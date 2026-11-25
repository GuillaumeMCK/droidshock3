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

/// Usage: bridge [--process-path <path>] [--client-pid <pid>]
/// [--usb-config-bak <sys.usb.config>]
///
/// Writes `<pid>:<port>` to the process file once listening, and deletes it
/// on shutdown.
void main(List<String> args) => runZonedGuarded(() => _run(args), _onFatal);

Future<void> _run(List<String> args) async {
  final Map<String, String> options = _parseOptions(args);
  final File processFile = File(options['--process-path'] ?? kProcessPath);

  // Before Ds3Bridge.start: usb_gadget loads the library on first use.
  _writeNativeLibrary();

  final Ds3Bridge bridge = await Ds3Bridge.start(
    clientPid: int.tryParse(options['--client-pid'] ?? ''),
    usbConfigBackup: options['--usb-config-bak'],
  );
  stdout.writeln(
    'listening on ${InternetAddress.loopbackIPv4.address}:'
    '${bridge.port}',
  );
  await processFile.writeAsString('$pid:${bridge.port}');

  await bridge.released;
  await processFile.delete();
  await _exit(0);
}

/// `--name value` pairs.
Map<String, String> _parseOptions(List<String> args) => {
  for (int i = 0; i + 1 < args.length; i += 2) args[i]: args[i + 1],
};

/// Writes the embedded library to [kNativeLibraryPath]. It's loaded by root,
/// so it's made read-only for others before it gets its name.
void _writeNativeLibrary() {
  final File partial = File('$kNativeLibraryPath.partial')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(base64.decode(nativeLibraryBase64));
  final ProcessResult chmod = Process.runSync('chmod', ['0644', partial.path]);
  if (chmod.exitCode != 0) {
    throw ProcessException('chmod', ['0644', partial.path], '${chmod.stderr}');
  }
  partial.renameSync(kNativeLibraryPath);
}

void _onFatal(Object error, StackTrace stack) {
  stderr
    ..writeln('--- Bridge encountered a fatal error ---')
    ..writeln('Error: $error')
    ..writeln('Stack trace:\n$stack');
  unawaited(_exit(1));
}

/// usb_gadget's native bridge keeps ports open after the gadget is removed,
/// so the isolate would never end on its own. exit() doesn't wait for
/// pending output.
Future<Never> _exit(int code) async {
  await [stdout.flush(), stderr.flush()].wait;
  exit(code);
}
