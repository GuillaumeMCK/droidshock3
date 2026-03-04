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

    final processFile = switch (args) {
      ['--process-path', final processPath] => File(processPath),
      _ => File(kProcessPath),
    };

    await Ds3Bridge.start.then((server) async {
      stdout.writeln(
        'listening on ${InternetAddress.anyIPv4.address}:${server.port}',
      );
      processFile.writeAsStringSync('$pid:${server.port}');
      await server.released;
    });
  },
  (err, st) {
    stderr.writeln('--- Bridge encountered a fatal error ---');
    stderr.writeln('Error: $err');
    stderr.writeln('Stack trace:\n$st');
    exit(1);
  },
);
