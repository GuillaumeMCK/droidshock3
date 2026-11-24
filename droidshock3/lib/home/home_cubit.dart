import 'dart:async';

import 'package:protocol/protocol.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepads/gamepads.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '/dualshock3/conversion.dart';
import '/bridge/bridge_cubit.dart';
import '/gamepad/gamepads_cubit.dart';

const motionRate = Duration(milliseconds: 20);

final class HomeState {
  const HomeState({this.motionEnabled = true});

  final bool motionEnabled;

  HomeState copyWith({bool? motionEnabled}) =>
      HomeState(motionEnabled: motionEnabled ?? this.motionEnabled);
}

final class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this._bridge, required GamepadsCubit gamepads})
    : super(const HomeState()) {
    _subscribeGamepad(gamepads);
    _outputSub = _bridge.outputReports.listen(_onOutputReport);
    _subscribeAccel();
    _subscribeGyro();
  }

  final BridgeCubit _bridge;

  StreamSubscription<(DS3Input, double)>? _inputSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<GamepadsState>? _gamepadStateSub;
  StreamSubscription<OutputReport>? _outputSub;

  GamepadController? _gamepad;
  Rumble? _rumble;

  void _subscribeGamepad(GamepadsCubit gamepads) {
    _select(gamepads.state.selected?.gamepad);
    _rewireInput(gamepads.state.selected?.onEvent);
    _gamepadStateSub = gamepads.stream.listen((state) {
      _select(state.selected?.gamepad);
      _rewireInput(state.selected?.onEvent);
    });
  }

  void _select(GamepadController? gamepad) {
    if (identical(gamepad, _gamepad)) return;
    unawaited(_gamepad?.stopRumble());
    _gamepad = gamepad;
    _rumble = null; // Applied again to the new gamepad on the next report.
  }

  /// Applies the host's rumble to the gamepad when it changes: the bridge
  /// repeats reports, which would restart a short effect each time.
  void _onOutputReport(OutputReport report) {
    final gamepad = _gamepad;
    final rumble = report.rumble;
    if (gamepad == null || rumble == _rumble) return;
    _rumble = rumble;
    final (:low, :high, :duration) = rumble;
    unawaited(
      low == 0 && high == 0
          ? gamepad.stopRumble()
          : gamepad.rumble(
              lowFrequency: low,
              highFrequency: high,
              duration: duration,
            ),
    );
  }

  void _rewireInput(Stream<(DS3Input, double)>? stream) {
    _inputSub?.cancel();
    _inputSub = stream?.listen((data) {
      final (input, value) = data;
      _bridge.emitReport(input, switch (value) {
        _ when (input.hasAnalog) => value.toDs3Pressure,
        _ when (input.isLeftStick) => value.toDs3Stick,
        _ when (input.isRightStick) => value.toDs3Stick,
        >= .1 => 255,
        _ => 0,
      });
    });
  }

  void toggleMotion() {
    final enabled = !state.motionEnabled;
    emit(state.copyWith(motionEnabled: enabled));
    if (enabled) {
      _subscribeAccel();
      _subscribeGyro();
    } else {
      _accelSub?.cancel();
      _gyroSub?.cancel();
      _bridge
        ..setAccel(0, 0, 0)
        ..setGyro(0)
        ..emitReport();
    }
  }

  void _subscribeAccel() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(samplingPeriod: motionRate)
        .listen((event) {
          final AccelerometerEvent(:x, :y, :z) = event;
          _bridge
            ..setAccel(x.toDs3Accel, y.toDs3Accel, z.toDs3Accel)
            ..emitReport();
        });
  }

  void _subscribeGyro() {
    _gyroSub?.cancel();
    _gyroSub = gyroscopeEventStream(samplingPeriod: motionRate).listen((event) {
      final GyroscopeEvent(:z) = event;
      _bridge
        ..setGyro(z.toDs3Gyro)
        ..emitReport();
    });
  }

  @override
  Future<void> close() {
    unawaited(_gamepad?.stopRumble());
    _outputSub?.cancel();
    _gamepadStateSub?.cancel();
    _inputSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    return super.close();
  }
}
