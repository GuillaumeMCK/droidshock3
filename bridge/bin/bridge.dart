import 'dart:async';
import 'dart:io';

import 'package:embed_annotation/embed_annotation.dart';
import 'package:bridge/bridge.dart';

part 'bridge.g.dart';

@EmbedBinary('/assets/libaio.so')
final List<int> libaioBytes = _$libaioBytes;

const kLibaioPath = '$kBridgeDir/libaio.so';

const kProcessPath = '$kBridgeDir/process';

void main(List<String> args) => runZonedGuarded(
  () async {
    final libaio = File(kLibaioPath);
    if (!libaio.existsSync()) libaio.writeAsBytesSync(libaioBytes);

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
  },
  (err, st) {
    stderr.writeln('--- Bridge encountered a fatal error ---');
    stderr.writeln('Error: $err');
    stderr.writeln('Stack trace:\n$st');
    exit(1);
  },
);
