import 'dart:async';

import '/common/common.dart';

final class JoystickState {
  const JoystickState({
    required this.origin,
    required this.xy,
    required this.isPressed,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
  });

  final Offset origin;
  final Offset xy;
  final bool isPressed;
  final void Function(Offset pos) onStart;
  final void Function(Offset pos) onMove;
  final void Function() onEnd;
}

JoystickState useJoystick({
  required double maxRadius,
  void Function(Offset position)? onPositionChanged,
  void Function(bool isPressed)? onPressed,
}) {
  final origin = useState(Offset.zero);
  final xy = useState(Offset.zero);
  final isPressed = useState(false);
  final pendingTapTimer = useRef<Timer?>(null);

  useEffect(() {
    return () => pendingTapTimer.value?.cancel();
  }, const []);

  final onStart = useCallback((Offset pos) {
    origin.value = pos;
    if (pendingTapTimer.value != null) {
      pendingTapTimer.value!.cancel();
      pendingTapTimer.value = null;
      onPressed?.call(isPressed.value = true);
    } else {
      pendingTapTimer.value = Timer(
        const Duration(milliseconds: 250),
        () => pendingTapTimer.value = null,
      );
    }
  }, [onPressed]);

  final onMove = useCallback((Offset pos) {
    final delta = pos - origin.value;
    final dist = delta.distance;
    final clamped = dist <= maxRadius
        ? delta
        : Offset(delta.dx / dist * maxRadius, delta.dy / dist * maxRadius);
    xy.value = clamped;
    onPositionChanged?.call(clamped / maxRadius);
  }, [maxRadius, onPositionChanged]);

  final onEnd = useCallback(() {
    origin.value = Offset.zero;
    xy.value = Offset.zero;
    onPositionChanged?.call(Offset.zero);
    onPressed?.call(isPressed.value = false);
  }, [onPositionChanged, onPressed]);

  return JoystickState(
    origin: origin.value,
    xy: xy.value,
    isPressed: isPressed.value,
    onStart: onStart,
    onMove: onMove,
    onEnd: onEnd,
  );
}
