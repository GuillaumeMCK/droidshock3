import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bridge/bridge.dart';
import 'package:embed_annotation/embed_annotation.dart';
import 'package:protocol/protocol.dart';

part 'bridge.g.dart';

/// usb_gadget's native library, built by tool/build_bridge.sh.
@EmbedBinary('/assets/libusb_gadget_native.so', base64: true)
const String nativeLibraryBase64 = _$nativeLibraryBase64;

/// Where the library is written: the path tool/build_bridge.sh maps
/// usb_gadget's code asset to.
const kNativeLibraryPath = '$kBridgeDir/libusb_gadget_native.so';

const kProcessPath = '$kBridgeDir/process';

/// Writes the embedded library to [kNativeLibraryPath]. It's loaded by root,
/// so it's made read-only for others before it gets its name.
void writeNativeLibrary() {
  final partial = File('$kNativeLibraryPath.partial')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(base64.decode(nativeLibraryBase64));
  final chmod = Process.runSync('chmod', ['0644', partial.path]);
  if (chmod.exitCode != 0) {
    throw ProcessException('chmod', ['0644', partial.path], '${chmod.stderr}');
  }
  partial.renameSync(kNativeLibraryPath);
}

void main(List<String> args) => runZonedGuarded(
  () async {
    // Before Ds3Bridge.start: usb_gadget loads the library on first use.
    writeNativeLibrary();

    File? processFile;
    int? clientPid;
    String? usbConfigBak;

    for (var i = 0; i < args.length - 1; i++) {
      switch (args[i]) {
        case '--process-path':
          processFile = File(args[i + 1]);
        case '--client-pid':
          clientPid = int.tryParse(args[i + 1]);
        case '--usb-config-bak':
          usbConfigBak = args[i + 1];
      }
    }
    processFile ??= File(kProcessPath);

    final server = await Ds3Bridge.start(
      clientPid: clientPid,
      usbConfigBak: usbConfigBak,
    );
    stdout.writeln(
      'listening on ${InternetAddress.anyIPv4.address}:${server.port}',
    );
    await processFile.writeAsString('$pid:${server.port}');
    await server.released;
    await processFile.delete();
    // usb_gadget's native bridge keeps ports open after the gadget is
    // removed, so the isolate would never finish on its own. exit() doesn't
    // wait for pending output.
    await [stdout.flush(), stderr.flush()].wait;
    exit(0);
  },
  (err, st) {
    stderr.writeln('--- Bridge encountered a fatal error ---');
    stderr.writeln('Error: $err');
    stderr.writeln('Stack trace:\n$st');
    exit(1);
  },
);
