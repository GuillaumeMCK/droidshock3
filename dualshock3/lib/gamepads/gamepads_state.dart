part of 'gamepads_cubit.dart';

final class GamepadsState extends Iterable<GamepadInfo> {
  GamepadsState() : _gamepads = {};

  final Map<int, GamepadInfo> _gamepads;

  GamepadInfo? _paired;

  GamepadInfo? get pair => _paired;

  void set pair(GamepadInfo? name) => switch (name) {
    GamepadInfo(:final id) when _gamepads.containsKey(id) => _paired = name,
    _ => null,
  };

  void update(List<GamepadInfo> current) {
    for (final info in current) {
      _gamepads[info.id] = info;
    }
    if (_paired case GamepadInfo(:final id) when this[id] == null) {
      _paired = null;
    }
  }

  void remove(int id) {
    if (_paired case GamepadInfo(:final id) when id == id) {
      _paired = null;
    }
    if (this[id] != null) {
      _gamepads.remove(id);
    }
  }

  @override
  Iterator<GamepadInfo> get iterator => _gamepads.values.iterator;

  GamepadInfo? operator [](int id) => _gamepads[id];
}
