import 'dart:async';

import 'package:gamepads/gamepads.dart';

import '/common/common.dart';

part 'gamepads_state.dart';

@lazySingleton
class GamepadsCubit extends Cubit<GamepadsState> with AppLogger {
  GamepadsCubit() : super(GamepadsState()) {
    _pollingTimer = .periodic(const Duration(seconds: 1), (_) async {
      final gamepads = await Gamepads.list();
      _onNewGamepads(gamepads);
    });
  }

  late Timer _pollingTimer;

  void _onNewGamepads(List<GamepadController> gamepads) {
    final newState = state.clone..update(gamepads);
    if (state == newState) return;
    log?.debug('Received gamepad update: [${gamepads.join(', ')}]');
    emit(newState);
  }

  @override
  Future<void> close() async {
    _pollingTimer.cancel();
    return super.close();
  }
}
