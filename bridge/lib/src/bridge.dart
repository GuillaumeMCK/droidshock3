import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffsds3/ffsds3.dart';
import 'package:using/using.dart';

import 'logger.dart';
import 'session.dart';
import 'protocol.dart';

const kBridgeDir = '/data/local/tmp/ds3_bridge';

final class Ds3Bridge with Releasable, BridgeLogger {
  /// A single-client TCP server that bridges between a DualShock 3 gadget
  /// and a client speaking the simple protocol defined in protocol.dart.
  Ds3Bridge._(this._server, this._gadget, this._ds3) {
    _server.listen(_onIncoming, onDone: release, cancelOnError: false);
    _outputTimer = .periodic(const Duration(milliseconds: 10), (_) {
      if (_session case Session(isReleased: true)?) return;
      _session?.sendOutput(_ds3.output.bytes);
    });
  }

  static Future<Ds3Bridge> get start async {
    late final RawServerSocket server;
    final (gadget, ds3) = createDualshock3();
    try {
      server = await RawServerSocket.bind(InternetAddress.anyIPv4, 0);
      await gadget.register().then((reg) => reg.bind(defaultUDC));
      return Ds3Bridge._(server, gadget, ds3);
    } catch (_) {
      await server.close();
      await gadget.remove();
      rethrow;
    }
  }

  final Gadget _gadget;
  final Dualshock3 _ds3;
  final RawServerSocket _server;
  final Completer<void> _released = Completer();

  Future<void> get released => _released.future;

  int get port => _server.port;
  Session? _session;
  Timer? _outputTimer;

  Future<void> _onIncoming(RawSocket socket) async {
    if (_session != null) {
      log.warn(
        'Rejected connection from ${socket.remoteAddress} - already have a client',
      );
      socket.close();
      return;
    }
    log.info('Client connected: ${socket.remoteAddress.address}');
    _session ??= Session(
      socket: socket,
      onFrame: _onFrame,
      onClose: _onSessionClosed,
    );
  }

  void _onFrame(Op op, Uint8List payload) {
    switch (op) {
      case Op.inputReport:
        _ds3.input.bytes.setRange(0, 48, payload);
      case Op.shutdown:
        release();
    }
  }

  void _onSessionClosed() {
    log.info('Client disconnected: ${_session?.remoteAddress}');
    _session?.release();
    _session = null;
  }

  @override
  Future<void> release() async {
    if (isReleased) return;
    super.release();
    _outputTimer?.cancel();
    _outputTimer = null;

    _session?.release();
    _session = null;

    await _server.close();
    await _gadget.remove();
    _released.complete();
  }
}
