part of 'gamepads_cubit.dart';

final class GamepadsState extends Iterable<GamepadController> {
  GamepadsState() : _gamepads = {};

  final Map<String, GamepadController> _gamepads;

  GamepadState? _selected;

  GamepadState? get selected => _selected;

  set selected(GamepadController? gamepad) => switch (gamepad) {
    GamepadController(:final id) when _gamepads.containsKey(id) =>
      _selected = .new(_gamepads[id]!),
    _ => null,
  };

  void update(List<GamepadController> gamepads) {
    _gamepads.clear();
    for (final gamepad in gamepads) {
      _gamepads[gamepad.id] = gamepad;
    }
    if (_selected case GamepadState(:final id)? when _gamepads[id] == null) {
      _selected = null;
    }
  }

  void remove(String id) {
    if (_selected case GamepadController(:final id) when id == id) {
      _selected = null;
    }
    if (_gamepads[id] != null) {
      _gamepads.remove(id);
    }
  }

  GamepadsState get clone => GamepadsState()
    .._gamepads.addAll(_gamepads)
    .._selected = _selected;

  GamepadController? operator [](int id) => elementAt(id);

  @override
  Iterator<GamepadController> get iterator => _gamepads.values.iterator;

  @override
  bool operator ==(Object other) =>
      other is GamepadsState &&
      selected?.id == other.selected?.id &&
      selected?.name == other.selected?.name &&
      _gamepads.length == other._gamepads.length &&
      _gamepads.keys.every(other._gamepads.containsKey);

  @override
  int get hashCode => Object.hash(_gamepads.keys.toSet(), _selected);
}
