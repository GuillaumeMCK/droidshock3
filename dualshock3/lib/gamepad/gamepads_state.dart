part of 'gamepads_cubit.dart';

final class GamepadsState extends Iterable<GamepadController> {
  GamepadsState() : _gamepads = {};

  final Map<String, GamepadController> _gamepads;

  GamepadController? _paired;

  GamepadController? get pair => _paired;

  set pair(GamepadController? gamepad) => switch (gamepad) {
    GamepadController(:final id) when _gamepads.containsKey(id) =>
      _paired = gamepad,
    _ => null,
  };

  void update(List<GamepadController> gamepads) {
    _gamepads.clear();
    for (final gamepad in gamepads) {
      _gamepads[gamepad.id] = gamepad;
    }
    if (_paired case GamepadController(:final id)? when _gamepads[id] == null) {
      _paired = null;
    }
  }

  void remove(String id) {
    if (_paired case GamepadController(:final id) when id == id) {
      _paired = null;
    }
    if (_gamepads[id] != null) {
      _gamepads.remove(id);
    }
  }

  GamepadsState get clone => GamepadsState()
    .._gamepads.addAll(_gamepads)
    .._paired = _paired;

  GamepadController? operator [](int id) => elementAt(id);

  @override
  Iterator<GamepadController> get iterator => _gamepads.values.iterator;

  @override
  bool operator ==(Object other) =>
      other is GamepadsState &&
      pair?.id == other.pair?.id &&
      pair?.name == other.pair?.name &&
      _gamepads.length == other._gamepads.length &&
      _gamepads.keys.every(other._gamepads.containsKey);

  @override
  int get hashCode => Object.hash(_gamepads.keys.toSet(), _paired);
}
