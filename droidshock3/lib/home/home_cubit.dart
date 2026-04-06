import 'dart:async';

import 'package:ffsds3/ffsds3.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '/dualshock3/conversion.dart';
import '/bridge/bridge_cubit.dart';
import '/gamepad/gamepads_cubit.dart';

const motionRate = Duration(milliseconds: 20);

final class HomeState {
  const HomeState({this.motionEnabled = false});

  final bool motionEnabled;

  HomeState copyWith({bool? motionEnabled}) =>
      HomeState(motionEnabled: motionEnabled ?? this.motionEnabled);
}

final class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required BridgeCubit bridge, required GamepadsCubit gamepads})
    : _bridge = bridge,
      super(const HomeState()) {
    _subscribeGamepad(gamepads);
    _subscribeAccel();
    _subscribeGyro();
  }

  final BridgeCubit _bridge;

  StreamSubscription<(DS3Input, double)>? _inputSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<GamepadsState>? _gamepadStateSub;

  void _subscribeGamepad(GamepadsCubit gamepads) {
    _rewireInput(gamepads.state.selected?.onEvent);
    _gamepadStateSub = gamepads.stream.listen((state) {
      _rewireInput(state.selected?.onEvent);
    });
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
    _accelSub = accelerometerEventStream(samplingPeriod: motionRate).listen((
      event,
    ) {
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
    _gamepadStateSub?.cancel();
    _inputSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    return super.close();
  }
}
