import 'package:flutter/gestures.dart';
import '/common/common.dart';
import 'joystick_hook.dart';

final class Joystick extends HookWidget {
  const Joystick({
    super.key,
    required this.size,
    required this.knobSize,
    this.onPositionChanged,
    this.onPressed,
  });

  final double size;
  final double knobSize;
  final void Function(Offset position)? onPositionChanged;
  final void Function(bool isPressed)? onPressed;

  @override
  Widget build(BuildContext context) {
    final JoystickState(
      :onStart,
      :onEnd,
      :onMove,
      :isPressed,
      :origin,
      :xy,
    ) = useJoystick(
      maxRadius: size / 4,
      onPositionChanged: onPositionChanged,
      onPressed: onPressed,
    );

    final baseRadius = size / 2;

    return RawGestureDetector(
      behavior: .opaque,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => .new(duration: const Duration(milliseconds: 1)),
              (i) {
                i.onLongPressStart = (d) => onStart(d.localPosition);
                i.onLongPressMoveUpdate = (d) => onMove(d.localPosition);
                i.onLongPressCancel = onEnd;
                i.onLongPressUp = onEnd;
              },
            ),
      },
      child: Stack(
        fit: .expand,
        clipBehavior: .none,
        children: [
          if (xy == Offset.zero)
            Center(
              child: _Knob(knobSize: knobSize, isPressed: isPressed),
            ),
          if (origin != Offset.zero) ...[
            Positioned(
              top: origin.dy - baseRadius / 2,
              left: origin.dx - baseRadius / 2,
              child: _Circle(size: baseRadius),
            ),
            Positioned(
              top: origin.dy + xy.dy - knobSize / 2,
              left: origin.dx + xy.dx - knobSize / 2,
              child: SizedBox.square(
                dimension: knobSize,
                child: Center(
                  child: _Knob(knobSize: knobSize, isPressed: isPressed),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _Knob extends StatelessWidget {
  const _Knob({required this.knobSize, this.isPressed = false});

  final double knobSize;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme) = context.theme;
    return SizedBox.square(
      dimension: knobSize / 1.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.ds3Bg,
          borderRadius: .circular(knobSize / 2),
        ),
        child: Icon(
          LucideIcons.target200,
          size: knobSize / 1.8,
          color: isPressed ? colorScheme.ds3Fg : colorScheme.ds3Border,
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme) = context.theme;
    final primary = colorScheme.card;
    final secondary = colorScheme.ds3Pad.shiftLightness();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: .circular(size / 2),
        border: .all(color: primary, width: 3),
        gradient: RadialGradient(colors: [secondary.alphaTrace, primary]),
      ),
    );
  }
}
