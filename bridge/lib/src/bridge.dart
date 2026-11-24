import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffsds3/ffsds3.dart';
import 'package:using/using.dart';

import 'logger.dart';
import 'session.dart';

/// Single-client TCP bridge between a DualShock 3 USB gadget and a Flutter client.
final class Ds3Bridge with Releasable, BridgeLogger {
  Ds3Bridge._(
    this._server,
    this._gadget,
    this._ds3, {
    int? clientPid,
    String? usbConfigBak,
  }) : _usbConfigBak = usbConfigBak {
    _server.listen(_onIncoming, onDone: release, cancelOnError: false);
    _ds3.onOutputReport = (_) => _sendOutputReport();
    if (clientPid != null) _watchPid(clientPid);
  }

  static Future<Ds3Bridge> start({int? clientPid, String? usbConfigBak}) async {
    final (gadget, ds3) = createDualshock3();
    RawServerSocket? server;
    try {
      server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      await gadget.bind();
      return Ds3Bridge._(
        server,
        gadget,
        ds3,
        clientPid: clientPid,
        usbConfigBak: usbConfigBak,
      );
    } catch (_) {
      await server?.close();
      await gadget.remove();
      rethrow;
    }
  }

  final Gadget _gadget;
  final Dualshock3 _ds3;
  final RawServerSocket _server;
  final Completer<void> _released = .new();

  Session? _session;
  String? _usbConfigBak;
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
    _sendOutputReport(); // The host's last one, LEDs included.
  }

  /// Forwards the host's output report as it arrives, rumble included.
  void _sendOutputReport() {
    final session = _session;
    if (session == null || session.isReleased) return;
    session.send(Op.outputReport, _ds3.output.bytes);
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
    _watchdogTimer = .periodic(kPidPollInterval, (_) async {
      if (!Directory('/proc/$pid').existsSync()) {
        await release();
      }
    });
  }

  Future<void> _restoreUsbConfig() async {
    if (_usbConfigBak == null) return;
    try {
      await Process.run('sh', [
        '-c',
        'setprop sys.usb.config "$_usbConfigBak"',
      ]);
    } on Object catch (err, st) {
      log.error('Failed to restore USB config:', err, st);
    }
  }

  @override
  Future<void> release() async {
    if (isReleased) return;
    super.release();

    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    _ds3.onOutputReport = null;

    _session?.release();
    _session = null;

    await _server.close();
    await _gadget.remove();

    await _restoreUsbConfig();
    _released.complete();
  }
}
