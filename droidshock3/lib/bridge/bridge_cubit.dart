import 'dart:async';
import 'dart:io';

import 'package:ffsds3/ffsds3.dart';
import 'package:flutter/services.dart';
import 'package:root_plus/root_plus.dart';
import 'package:bridge/bridge.dart';

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

  List<bool> get ledStates => _outputReport.ledStates;

  static const kExePath = '$kBridgeDir/bridge';
  static final logPath = '$fTmpDir/bridge.log';
  static final processPath = '$fTmpDir/process';

  void _onOutput(Uint8List data) {
    _buffer.addAll(data);
    while (_buffer.length >= Op.frameLength) {
      switch (Op.parseServerFrame(_buffer[0])) {
        case .outputReport:
          _outputReport.update(_buffer.sublist(1, Op.frameLength));
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
    _socket?.add([Op.inputReport.byte, ..._inputReport.bytes]);
  }

  void setLeftStick(DS3Joystick value) => _inputReport.setLeftStick(value);

  void setRightStick(DS3Joystick value) => _inputReport.setRightStick(value);

  Future<void> setup() async => runZonedGuarded(() async {
    if (state.type case .setup || .ready || .connected) {
      return log?.warn('Setup already in progress or completed');
    }
    emit(.setup);
    final exeTmpPath = '$fTmpDir/bridge';
    final bytes = await rootBundle.load(Assets.bridge);
    await File(exeTmpPath).writeAsBytes(bytes.buffer.asUint8List());
    await RootPlus.executeRootCommand('''
      if [ -f $processPath ]; then
        sleep ${kPidPollInterval.inSeconds}
        rm -f $processPath
      fi
      
      if [ -d $kBridgeDir ]; then
        rm -rf $kBridgeDir
      fi
      
      if [ ! -d /sys/kernel/config/usb_gadget ]; then
        mount -t configfs none /sys/kernel/config
      fi

      USB_CONFIG_BAK=\$(getprop persist.sys.usb.config)
      setprop sys.usb.config none

      mkdir -p $kBridgeDir
      mv $exeTmpPath $kExePath
      chmod +x $kExePath

      export LD_LIBRARY_PATH=$kBridgeDir
      nohup $kExePath --process-path $processPath --client-pid $pid --usb-config-bak "\$USB_CONFIG_BAK" > $logPath 2>&1 &
    
      timeout 3 sh -c 'until [ -f $processPath ]; do sleep 0.1; done'
    ''');
    emit(.ready);
  }, _onError);

  Future<void> connect() async => runZonedGuarded(() async {
    if (state.type != .ready) {
      return log?.warn('Start bridge called before setup');
    }

    final infos = File(processPath).readAsStringSync();
    if (infos.isEmpty) {
      throw Exception('Failed to start bridge, no process info found');
    }

    final [bridgePid, port] = [...infos.split(':').map(int.parse)];
    _socket ??= await Socket.connect(InternetAddress.loopbackIPv4, port);
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

    await _listener?.cancel();
    _listener = null;
    await _socket?.close();
    _socket = null;
    _outputStream = null;
    _buffer.clear();

    await RootPlus.executeRootCommand('''
      sleep ${kPidPollInterval.inSeconds}
      if [ -f $processPath ]; then
        kill \$(cut -d: -f1 $processPath)
        rm -f $processPath
      fi
      rm -rf $kBridgeDir
    ''');

    emit(.none);
  }, _onError);

  Future<void> _onError(Object err, StackTrace st) async {
    emit(.error(err, st));
    await shutdown();
    emit(.closed(state));
  }

  @override
  Future<void> close() async {
    await shutdown();
    emit(.closed(state));
    return super.close();
  }
}