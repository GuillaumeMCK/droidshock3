import 'dart:async';
import 'dart:io';

import 'package:embed_annotation/embed_annotation.dart';
import 'package:bridge/bridge.dart';
import 'package:ffsds3/ffsds3.dart' show Logger;

part 'bridge.g.dart';

@EmbedBinary('/assets/libaio.so')
final List<int> libaioBytes = _$libaioBytes;

const kLibaioPath = '$kBridgeDir/libaio.so';

void main() => runZonedGuarded(
  () async {
    final libaio = File(kLibaioPath);
    if (!libaio.existsSync()) libaio.writeAsBytesSync(libaioBytes);

    await Ds3Bridge.start().then((server) async {
      Logger.root.info(
        'listening on ${InternetAddress.anyIPv4.address}:${server.port}',
      );
      await server.released;
    });
  },
  (err, st) {
    Logger.root.fatal('Fatal error in bridge', err, st);
    exit(1);
  },
);
