import '/app/app_shell.dart';

import '/common/common.dart';

import 'display/pad.dart';
import 'inputs/inputs.dart';

class RightPad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final constraints = context.watch<AppConstraints>();
    final size = constraints.maxWidth / 8;
    return Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        Pad(dimension: size * 3.25),
        Positioned.fill(
          child: Joystick(
            size: constraints.maxWidth / 1.5,
            knobSize: constraints.maxWidth / 8,
            onPressed: (isPressed) => print('double tap $isPressed'),
            onPositionChanged: (position) => print('position $position'),
          ),
        ),
        SizedBox.square(
          dimension: size * 3,
          child: Stack(
            children: [
              Align(
                alignment: .topCenter,
                child: TriangleButton(size: size, onPressed: (isPressed) {}),
              ),
              Align(
                alignment: .centerLeft,
                child: SquareButton(size: size, onPressed: (isPressed) {}),
              ),
              Align(
                alignment: .centerRight,
                child: CircleButton(size: size, onPressed: (isPressed) {}),
              ),
              Align(
                alignment: .bottomCenter,
                child: CrossButton(size: size, onPressed: (isPressed) {}),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LeftPad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final constraints = context.watch<AppConstraints>();
    final size = constraints.maxWidth / 8;
    return Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        Pad(dimension: size * 3.25),
        Positioned.fill(
          child: Joystick(
            size: constraints.maxWidth / 1.5,
            knobSize: constraints.maxWidth / 8,
            onPressed: (isPressed) => print('double tap $isPressed'),
            onPositionChanged: (position) => print('position $position'),
          ),
        ),
        SizedBox.square(
          dimension: size * 3,
          child: Stack(
            children: [
              Align(
                alignment: .topCenter,
                child: DirectionButton.down(
                  size: size,
                  onPressed: (isPressed) {},
                ),
              ),
              Align(
                alignment: .centerLeft,
                child: DirectionButton.right(
                  size: size,
                  onPressed: (isPressed) {},
                ),
              ),
              Align(
                alignment: .centerRight,
                child: DirectionButton.left(
                  size: size,
                  onPressed: (isPressed) {},
                ),
              ),
              Align(
                alignment: .bottomCenter,
                child: DirectionButton.up(
                  size: size,
                  onPressed: (isPressed) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Dualshock3Widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final constraints = context.watch<AppConstraints>();
    final size = constraints.maxWidth / 3.5;
    return Padding(
      padding: .symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: .min,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Container(
                padding: .all(6),
                decoration: BoxDecoration(
                  color: colorScheme.border.alphaFaint,
                  borderRadius: .circular(8),
                ),
                child: Column(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    LButton(2, width: size, onPressed: (isPressed) {}),
                    LButton(1, width: size, onPressed: (isPressed) {}),
                  ],
                ),
              ),
              Container(
                padding: .all(6),
                decoration: BoxDecoration(
                  color: colorScheme.border.alphaFaint,
                  borderRadius: .circular(8),
                ),
                child: Column(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    RButton(2, width: size, onPressed: (isPressed) {}),
                    RButton(1, width: size, onPressed: (isPressed) {}),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: constraints.maxHeight / 2.75,
            alignment: .center,
            child: Row(
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .stretch,
              children: [LeftPad(), RightPad()],
            ),
          ),
          Row(
            spacing: 16,
            mainAxisAlignment: .center,
            children: [
              SelectButton(onPressed: (isPressed) {}),
              PSButton(
                size: constraints.maxWidth / 12,
                onPressed: (isPressed) {},
              ),
              StartButton(onPressed: (isPressed) {}),
            ],
          ),
        ],
      ),
    );
  }
}
