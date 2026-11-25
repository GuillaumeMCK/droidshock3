import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffsds3/ffsds3.dart';
import 'package:using/using.dart';

import 'logger.dart';
import 'session.dart';

/// Bridges the DualShock 3 USB gadget and one client on a loopback TCP port:
/// the client's input reports go to the host, the host's output reports to
/// the client.
final class Ds3Bridge with Releasable, BridgeLogger {
  Ds3Bridge._(this._server, this._gadget, this._ds3, {this.usbConfigBackup}) {
    _server.listen(_onConnection, onDone: release);
    _ds3.onOutputReport = (_) => _sendOutputReport();
  }

  /// Binds the gadget to the USB controller and starts listening.
  ///
  /// Shuts down when the client asks to, or once [clientPid] exits, if given.
  /// Then restores `sys.usb.config` to [usbConfigBackup], if given.
  static Future<Ds3Bridge> start({
    int? clientPid,
    String? usbConfigBackup,
  }) async {
    final (gadget, ds3) = createDualshock3();
    RawServerSocket? server;
    try {
      server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      await gadget.bind();
    } catch (_) {
      await server?.close();
      await gadget.remove();
      rethrow;
    }
    final bridge = Ds3Bridge._(
      server,
      gadget,
      ds3,
      usbConfigBackup: usbConfigBackup,
    );
    if (clientPid != null) bridge._watchClient(clientPid);
    return bridge;
  }

  final String? usbConfigBackup;

  final RawServerSocket _server;
  final Gadget _gadget;
  final Dualshock3 _ds3;
  final Completer<void> _released = .new();

  Session? _session;
  Timer? _clientWatchdog;

  int get port => _server.port;

  /// Completes once [release] has removed the gadget.
  Future<void> get released => _released.future;

  void _onConnection(RawSocket socket) {
    if (_session case final Session session) {
      log.warn(
        'Rejected ${socket.remoteAddress.address}: '
        '${session.address} is connected',
      );
      socket.close();
      return;
    }
    final Session session = _session = Session(
      socket,
      onFrame: _onFrame,
      onClose: _onSessionClosed,
    );
    log.info('Client connected: ${session.address}');
    _sendOutputReport(); // The host's last one, LEDs included.
  }

  void _onSessionClosed() {
    log.info('Client disconnected: ${_session?.address}');
    _session = null;
  }

  void _onFrame(Op op, Uint8List payload) => switch (op) {
    .inputReport => _ds3.input.update(payload),
    .shutdown => release(),
    .outputReport => log.warn('Unexpected output report from the client'),
  };

  /// Forwards the host's output report, rumble included, as it arrives.
  void _sendOutputReport() => _session?.send(.outputReport, _ds3.output.bytes);

  void _watchClient(int pid) {
    log.info('Watching client PID $pid');
    _clientWatchdog = .periodic(kPidPollInterval, (_) {
      if (!Directory('/proc/$pid').existsSync()) release();
    });
  }

  Future<void> _restoreUsbConfig(String config) async {
    try {
      final ProcessResult result = await Process.run('setprop', [
        'sys.usb.config',
        config,
      ]);
      if (result.exitCode != 0) {
        log.error('Failed to restore USB config: ${result.stderr}');
      }
    } on Object catch (err, st) {
      log.error('Failed to restore USB config:', err, st);
    }
  }

  /// Stops the bridge: the client, the server, then the gadget. Further
  /// calls do nothing; [released] completes when it's done.
  @override
  Future<void> release() async {
    if (isReleased) return;
    super.release();

    _clientWatchdog?.cancel();
    _ds3.onOutputReport = null;
    _session?.release();

    await _server.close();
    await _gadget.remove();
    if (usbConfigBackup case final String config) {
      await _restoreUsbConfig(config);
    }
    _released.complete();
  }
}
