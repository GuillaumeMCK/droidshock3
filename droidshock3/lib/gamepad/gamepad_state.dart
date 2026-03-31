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
  GamepadState(this.gamepad) : _mapping = Map.of(defaultMapping);

  final GamepadController gamepad;
  Map<Enum, DS3Input> _mapping;

  String get id => gamepad.id;

  String get name => gamepad.name;

  Map<String, bool> get buttons => gamepad.state.buttonInputs;

  Map<String, double> get analog => gamepad.state.analogInputs;

  Map<Enum, DS3Input> get mapping => Map.unmodifiable(_mapping);

  void remap(DS3Input a, DS3Input b) {
    final keyA = _keyFor(a);
    final keyB = _keyFor(b);
    if (keyA != null && keyB != null) {
      final tmp = _mapping[keyA];
      _mapping[keyA] = _mapping[keyB] ?? defaultMapping[keyB]!;
      _mapping[keyB] = tmp ?? defaultMapping[keyA]!;
    }
  }

  void restoreMap() => _mapping = Map.of(defaultMapping);

  void dispose() => gamepad.dispose();

  Stream<(DS3Input, double)> get onEvent => Gamepads.normalizedEvents
      .where((e) => e.gamepadId == id) // Only events for this gamepad.
      .map((e) {
        final NormalizedGamepadEvent(:axis, :button, :value) = e;
        final ds3Input = _mapping[button ?? axis];
        if (ds3Input == null) throw AssertionError('Unknown gamepad input');
        return (ds3Input, value);
      });

  Stream<(DS3Input, double)> get onPressed {
    const debounce = Duration(milliseconds: 200);
    const threshold = .25;
    DateTime? last;
    return onEvent.where((e) {
      if (e.$2.abs() <= threshold) {
        return false;
      }
      final now = DateTime.now();
      if (last case DateTime d when now.difference(d) < debounce) {
        return false;
      }
      last = now;
      return true;
    });
  }

  Enum? _keyFor(DS3Input value) =>
      _mapping.entries.where((e) => e.value == value).firstOrNull?.key;
}
