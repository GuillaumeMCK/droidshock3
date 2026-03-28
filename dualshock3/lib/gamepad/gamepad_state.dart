import 'package:ffsds3/ffsds3.dart';
import 'package:gamepads/gamepads.dart';

const defaultMapping = {
  GamepadButton.dpadUp: DS3Input.up,
  GamepadButton.dpadRight: DS3Input.right,
  GamepadButton.dpadDown: DS3Input.down,
  GamepadButton.dpadLeft: DS3Input.left,
  GamepadButton.leftTrigger: DS3Input.l2,
  GamepadButton.rightTrigger: DS3Input.r2,
  GamepadAxis.rightTrigger: DS3Input.r2,
  GamepadAxis.leftTrigger: DS3Input.l2,
  GamepadButton.leftBumper: DS3Input.l1,
  GamepadButton.rightBumper: DS3Input.r1,
  GamepadButton.leftStick: DS3Input.l3,
  GamepadButton.rightStick: DS3Input.r3,
  GamepadAxis.rightStickX: DS3Input.rightStickX,
  GamepadAxis.rightStickY: DS3Input.rightStickY,
  GamepadAxis.leftStickX: DS3Input.leftStickX,
  GamepadAxis.leftStickY: DS3Input.leftStickY,
  GamepadButton.x: DS3Input.square,
  GamepadButton.a: DS3Input.cross,
  GamepadButton.b: DS3Input.circle,
  GamepadButton.y: DS3Input.triangle,
  GamepadButton.home: DS3Input.ps,
  GamepadButton.back: DS3Input.select,
  GamepadButton.start: DS3Input.start,
};

class GamepadState {
  GamepadState(this.gamepad) : _mapping = defaultMapping;

  final GamepadController gamepad;
  Map<Enum, DS3Input> _mapping;

  void editMap(Enum input, DS3Input ds3Input) {
    _mapping[input] = ds3Input;
  }

  void restoreMap() {
    _mapping = defaultMapping;
  }

  String get name => gamepad.name;

  String get id => gamepad.id;

  Map<String, bool> get buttons => gamepad.state.buttonInputs;

  Map<String, double> get analog => gamepad.state.analogInputs;

  Stream<(DS3Input, double)> get onEvent => Gamepads.normalizedEvents
      .where((e) => e.gamepadId == gamepad.id)
      .map((e) {
        final NormalizedGamepadEvent(:axis, :button, :value) = e;
        final ds3Input = _mapping[button ?? axis];
        if (ds3Input == null) throw AssertionError('Unknown gamepad input');
        return (ds3Input, value);
      });

  Stream<(DS3Input, double)> get onPressed =>
      onEvent.where((e) => e.$2.abs() > .25);

  void dispose() {
    gamepad.dispose();
  }
}
