import 'dart:async';
import 'dart:io';

import 'package:protocol/protocol.dart';
import 'package:flutter/services.dart';

import '/bootstrap/bootstrap_cubit.dart';
import '/common/common.dart';

part 'bridge_state.dart';

@lazySingleton
class BridgeCubit extends Cubit<BridgeState> with AppLogger {
  BridgeCubit() : super(.none);

  Socket? _socket;
  Stream<Uint8List>? _outputStream;
  StreamSubscription<Uint8List>? _listener;

  final InputReport _inputReport = .new();
  final OutputReport _outputReport = .new();
  final List<int> _buffer = [];
  final StreamController<OutputReport> _outputReports = .broadcast();

  /// Since the last input report sent: they're sent at most once per
  /// [kInputReportInterval], which is as often as the gadget reads them.
  final Stopwatch _sinceSend = .new();
  Timer? _sendTimer;

  /// Output reports from the host, as the bridge forwards them: each one, as
  /// it arrives, changed or not, and the last one on connect.
  Stream<OutputReport> get outputReports => _outputReports.stream;

  List<bool> get ledStates => _outputReport.ledStates;

  static const kExePath = '$kBridgeDir/bridge';

  /// How long the bridge may take to start listening: it may first stop a
  /// previous one, and wait for Android to free USB.
  static const kStartTimeout = Duration(seconds: 15);
  static final logPath = '$fTmpDir/bridge.log';
  static final processPath = '$fTmpDir/process';

  void _onOutput(Uint8List data) {
    _buffer.addAll(data);
    while (_buffer.length >= Op.frameLength) {
      switch (Op.parseServerFrame(_buffer[0])) {
        case .outputReport:
          _outputReport.update(_buffer.sublist(1, Op.frameLength));
          _outputReports.add(_outputReport);
        default:
          throw UnimplementedError();
      }
      _buffer.removeRange(0, Op.frameLength);
    }
  }

  void emitReport([DS3Input? input, Object? value]) {
    if (state.type != .connected) {
      return log?.warn('Send input called when not connected');
    }
    if (input != null && value != null) {
      _inputReport.setInput(input, value);
    }
    if (_sendTimer != null) return; // Sends the latest state when it fires.
    final wait = kInputReportInterval - _sinceSend.elapsed;
    if (!_sinceSend.isRunning || wait <= .zero) return _sendReport();
    _sendTimer = .new(wait, _sendReport);
  }

  void _sendReport() {
    _sendTimer = null;
    _sinceSend
      ..reset()
      ..start();
    _socket?.add([Op.inputReport.byte, ..._inputReport.bytes]);
  }

  void setLeftStick(DS3Joystick value) => _inputReport.setLeftStick(value);

  void setRightStick(DS3Joystick value) => _inputReport.setRightStick(value);

  void setAccel(int x, int y, int z) => _inputReport.setAccel(x: x, y: y, z: z);

  void setGyro(int z) => _inputReport.gyroZ = z;

  Future<void> setup() async => runZonedGuarded(() async {
    if (state.type case .setup || .ready || .connected) {
      return log?.warn('Setup already in progress or completed');
    }
    emit(.setup);
    final String exeTmpPath = '$fTmpDir/bridge';
    final ByteData bytes = await rootBundle.load(Assets.bridge);
    await File(exeTmpPath).writeAsBytes(bytes.buffer.asUint8List());

    final File processFile = File(processPath);
    final String? previous = processFile.existsSync()
        ? processFile.readAsStringSync()
        : null;
    // Only installs and starts it: the bridge does the rest itself, logged
    // (bridge/bin/bridge.dart), stopping a previous one first.
    await su(
      'mkdir -p $kBridgeDir && mv -f $exeTmpPath $kExePath && '
      'chmod 0755 $kExePath && '
      '{ nohup $kExePath --process-path $processPath --client-pid $pid '
      '< /dev/null > $logPath 2>&1 & }',
    );
    await _waitForStart(processFile, previous);
    emit(.ready);
  }, _onError);

  /// Waits for the bridge to write a new process file, or to fail, which its
  /// log says.
  Future<void> _waitForStart(File processFile, String? previous) async {
    final File logFile = File(logPath);
    final Stopwatch waited = Stopwatch()..start();
    while (true) {
      if (processFile.existsSync()) {
        final String info = processFile.readAsStringSync();
        if (info.isNotEmpty && info != previous) return;
      }
      final String bridgeLog = logFile.existsSync()
          ? logFile.readAsStringSync()
          : '';
      if (bridgeLog.contains(kBridgeFatalError)) {
        throw Exception('The bridge failed to start:\n$bridgeLog');
      }
      if (waited.elapsed > kStartTimeout) {
        throw TimeoutException(
          'The bridge didn\'t start in ${kStartTimeout.inSeconds} s:\n'
          '$bridgeLog',
        );
      }
      await Future<void>.delayed(100.ms);
    }
  }

  Future<void> connect() async => runZonedGuarded(() async {
    if (state.type != .ready) {
      return log?.warn('Start bridge called before setup');
    }

    final infos = File(processPath).readAsStringSync();
    if (infos.isEmpty) {
      throw Exception('Failed to start bridge, no process info found');
    }

    final [bridgePid, port] = [...infos.split(':').map(int.parse)];
    _socket ??= await Socket.connect(InternetAddress.loopbackIPv4, port)
      // Frames are small and latency-bound: don't let Nagle hold them.
      ..setOption(SocketOption.tcpNoDelay, true);
    _outputStream ??= _socket?.asBroadcastStream(
      onListen: (subscription) => _listener ??= subscription,
      onCancel: (subscription) => _listener = null,
    )?..listen(_onOutput, onError: _onError);

    log?.info('Connected to bridge (PID: $bridgePid, Port: $port)');
    emit(.connected(port));
  }, _onError);

  Future<void> shutdown() async => runZonedGuarded(() async {
    if (state.type case .connected) {
      _socket?.add(Uint8List(Op.frameLength)..[0] = Op.shutdown.byte);
    }

    _sendTimer?.cancel();
    _sendTimer = null;
    _sinceSend
      ..stop()
      ..reset();
    await _listener?.cancel();
    _listener = null;
    await _socket?.close();
    _socket = null;
    _outputStream = null;
    _buffer.clear();

    await _stopBridge();
    emit(.none);
  }, _onError);

  /// Waits for the bridge to exit, which it does on the shutdown frame, else
  /// stops it: SIGTERM, which it cleans up on, then SIGKILL.
  Future<void> _stopBridge() async {
    final File processFile = File(processPath);
    if (await _exited(processFile)) return;
    final String bridgePid = processFile.readAsStringSync().split(':').first;
    // Only a bridge: the PID may have been reused since.
    String ifBridge(String command) =>
        'grep -q $kBridgeDir /proc/$bridgePid/cmdline 2>/dev/null && '
        '$command || true';

    log?.warn('Bridge $bridgePid still running: sending SIGTERM');
    await su(ifBridge('kill -TERM $bridgePid'));
    if (await _exited(processFile)) return;

    log?.warn('Bridge $bridgePid ignored SIGTERM: killing it');
    await su('${ifBridge('kill -KILL $bridgePid')}; rm -f $processPath');
  }

  /// Whether the bridge deletes [processFile], which it does last, within
  /// [timeout].
  Future<bool> _exited(
    File processFile, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final Stopwatch waited = Stopwatch()..start();
    while (processFile.existsSync()) {
      if (waited.elapsed > timeout) return false;
      await Future<void>.delayed(50.ms);
    }
    return true;
  }

  Future<void> _onError(Object err, StackTrace st) async {
    emit(.error(err, st));
    await shutdown();
    emit(.closed(state));
  }

  @override
  Future<void> close() async {
    await shutdown();
    await _outputReports.close();
    emit(.closed(state));
    return super.close();
  }
}
