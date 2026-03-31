import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffsds3/ffsds3.dart';
import 'package:using/using.dart';

import 'logger.dart';
import 'protocol.dart';
import 'session.dart';

const kBridgeDir = '/data/local/tmp/ds3_bridge';

/// How often to check whether the client process is still alive.
const _kPidPollInterval = Duration(seconds: 2);

/// How often to push DS3 output reports to the connected client.
const _kOutputInterval = Duration(milliseconds: 10);

/// Single-client TCP bridge between a DualShock 3 USB gadget and a Flutter client.
final class Ds3Bridge with Releasable, BridgeLogger {
  Ds3Bridge._(this._server, this._gadget, this._ds3, {int? clientPid}) {
    _server.listen(_onIncoming, onDone: release, cancelOnError: false);
    _outputTimer = .periodic(_kOutputInterval, (_) {
      _onSend(Op.outputReport, _ds3.output.bytes);
    });
    if (clientPid != null) _watchPid(clientPid);
  }

  static Future<Ds3Bridge> start({int? clientPid}) async {
    final (gadget, ds3) = createDualshock3();
    late final RawServerSocket server;
    try {
      server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      await gadget.register().then((r) => r.bind(defaultUDC));
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
  final Completer<void> _released = .new();

  Session? _session;
  Timer? _outputTimer;
  Timer? _watchdogTimer;

  int get port => _server.port;

  Future<void> get released => _released.future;

  Future<void> _onIncoming(RawSocket socket) async {
    if (_session != null) {
      log.warn(
        'Rejected connection from ${socket.remoteAddress} - already have a client',
      );
      socket.close();
      return;
    }
    log.info('Client connected: ${socket.remoteAddress.address}');
    _session = .new(
      socket: socket,
      onFrame: _onFrame,
      onClose: _onSessionClosed,
    );
  }

  void _onSend(Op op, Uint8List frame) {
    final session = _session;
    if (session == null || session.isReleased) return;
    switch (op) {
      case Op.outputReport:
        session.send(op, _ds3.output.bytes);
      default:
        throw UnimplementedError();
    }
  }

  void _onFrame(Op op, Uint8List frame) {
    switch (op) {
      case Op.inputReport:
        _ds3.input.update(frame);
      case Op.shutdown:
        release();
      default:
        throw UnimplementedError();
    }
  }

  void _onSessionClosed() {
    log.info('Client disconnected: ${_session?.remoteAddress}');
    _session?.release();
    _session = null;
  }

  void _watchPid(int pid) {
    log.info('Watching client PID $pid');
    _watchdogTimer = .periodic(_kPidPollInterval, (_) async {
      if (!Directory('/proc/$pid').existsSync()) {
        log.warn('Client PID $pid gone — shutting down');
        _watchdogTimer?.cancel();
        _watchdogTimer = null;
        await release();
      }
    });
  }

  void update(Uint8List frame) {}

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
