import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffsds3/ffsds3.dart';
import 'package:using/using.dart';

import 'logger.dart';
import 'session.dart';
import 'protocol.dart';

const kBridgeDir = '/data/local/tmp/ds3_bridge';

/// How often to check whether the client process is still alive.
const _kPidPollInterval = Duration(seconds: 2);

final class Ds3Bridge with Releasable, BridgeLogger {
  /// A single-client TCP server that bridges between a DualShock 3 gadget
  /// and a client speaking the simple protocol defined in protocol.dart.
  ///
  /// If [clientPid] is provided, the bridge will poll that process periodically
  /// and release itself gracefully when the process is no longer running.
  Ds3Bridge._(this._server, this._gadget, this._ds3, {int? clientPid}) {
    _server.listen(_onIncoming, onDone: release, cancelOnError: false);
    _outputTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_session case Session(isReleased: true)?) return;
      _session?.sendOutput(_ds3.output.bytes);
    });
    if (clientPid != null) {
      _startClientWatchdog(clientPid);
    }
  }

  static Future<Ds3Bridge> start({int? clientPid}) async {
    late final RawServerSocket server;
    final (gadget, ds3) = createDualshock3();
    try {
      server = await RawServerSocket.bind(InternetAddress.anyIPv4, 0);
      await gadget.register().then((reg) => reg.bind(defaultUDC));
      return Ds3Bridge._(server, gadget, ds3, clientPid: clientPid);
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
  Timer? _watchdogTimer;

  void _startClientWatchdog(int clientPid) {
    log.info('Watching client PID $clientPid for liveness');
    _watchdogTimer = Timer.periodic(_kPidPollInterval, (_) async {
      final alive = Directory('/proc/$clientPid').existsSync();
      if (!alive) {
        log.warn('Client PID $clientPid is gone — shutting down bridge');
        _watchdogTimer?.cancel();
        _watchdogTimer = null;
        await release();
      }
    });
  }

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

    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    _outputTimer?.cancel();
    _outputTimer = null;

    _session?.release();
    _session = null;

    await _server.close();
    await _gadget.remove();
    _released.complete();
  }
}
