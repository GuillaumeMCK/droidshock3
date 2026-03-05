import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_gamepad/universal_gamepad.dart';

import '/common/common.dart';

part 'gamepads_state.dart';

@lazySingleton
class GamepadsCubit extends Cubit<GamepadsState> with AppLogger {
  GamepadsCubit() : super(GamepadsState()) {
    _connectionEvents = _gamepad.connectionEvents.listen(_onConnectionEvent);
  }

  static final Gamepad _gamepad = .instance;

  late final StreamSubscription<GamepadConnectionEvent> _connectionEvents;

  void _onConnectionEvent(GamepadConnectionEvent event) async {
    switch (event) {
      case GamepadConnectionEvent(connected: true, :final info):
        log?.info('Gamepad connected: $info');
        state.update([info, ...state]);
      case GamepadConnectionEvent(connected: false, :final gamepadId):
        log?.info('Gamepad disconnected: $gamepadId');
        state.remove(gamepadId);
    }
  }

  @override
  Future<void> close() async {
    _connectionEvents.cancel();
    return super.close();
  }
}
