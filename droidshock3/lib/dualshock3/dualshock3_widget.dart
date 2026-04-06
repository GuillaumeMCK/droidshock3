import '/app/app_shell.dart';

import '/bridge/bridge_cubit.dart';
import '/common/common.dart';
import '/dualshock3/conversion.dart';

import 'widgets/display/pad.dart';
import 'widgets/inputs/inputs.dart';

class RightPad extends StatelessWidget {
  const RightPad({super.key});

  @override
  Widget build(BuildContext context) {
    final Size(:width) = context.watch<AppSize>();
    final bridge = context.read<BridgeCubit>();
    final btnSize = width / 8;
    return Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        Pad(dimension: btnSize * 3.25),
        Positioned.fill(
          child: Joystick(
            size: width / 1.5,
            knobSize: width / 7,
            onPressed: (value) => bridge.emitReport(.r3, value),
            onPositionChanged: (value) => bridge
              ..setRightStick((x: value.dx.toDs3Stick, y: value.dy.toDs3Stick))
              ..emitReport(),
          ),
        ),
        SizedBox.square(
          dimension: btnSize * 3,
          child: Stack(
            children: [
              Align(
                alignment: .topCenter,
                child: TriangleButton(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.triangle, value),
                ),
              ),
              Align(
                alignment: .centerLeft,
                child: SquareButton(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.square, value),
                ),
              ),
              Align(
                alignment: .centerRight,
                child: CircleButton(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.circle, value),
                ),
              ),
              Align(
                alignment: .bottomCenter,
                child: CrossButton(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.cross, value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LeftPad extends StatelessWidget {
  const LeftPad({super.key});

  @override
  Widget build(BuildContext context) {
    final Size(:width) = context.watch<AppSize>();
    final bridge = context.read<BridgeCubit>();
    final btnSize = width / 8;
    return Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        Pad(dimension: btnSize * 3.25),
        Positioned.fill(
          child: Joystick(
            size: width / 1.5,
            knobSize: width / 7,
            onPressed: (value) => bridge.emitReport(.l3, value),
            onPositionChanged: (value) => bridge
              ..setLeftStick((x: value.dx.toDs3Stick, y: value.dy.toDs3Stick))
              ..emitReport(),
          ),
        ),
        SizedBox.square(
          dimension: btnSize * 3,
          child: Stack(
            children: [
              Align(
                alignment: .topCenter,
                child: DirectionButton.down(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.up, value),
                ),
              ),
              Align(
                alignment: .centerLeft,
                child: DirectionButton.right(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.left, value),
                ),
              ),
              Align(
                alignment: .centerRight,
                child: DirectionButton.left(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.right, value),
                ),
              ),
              Align(
                alignment: .bottomCenter,
                child: DirectionButton.up(
                  size: btnSize,
                  onPressed: (value) => bridge.emitReport(.down, value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Triggers extends StatelessWidget {
  const Triggers({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final triggerSize = context.watch<AppSize>().width / 3.5;
    final bridge = context.read<BridgeCubit>();

    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Container(
          padding: .all(6),
          decoration: BoxDecoration(
            color: colorScheme.ds3Pad,
            borderRadius: .circular(8),
          ),
          child: Column(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              LButton(
                2,
                width: triggerSize,
                onPressed: (value) => bridge.emitReport(.l2, value),
              ),
              LButton(
                1,
                width: triggerSize,
                onPressed: (value) => bridge.emitReport(.l1, value),
              ),
            ],
          ),
        ),
        Container(
          padding: .all(6),
          decoration: BoxDecoration(
            color: colorScheme.ds3Pad,
            borderRadius: .circular(8),
          ),
          child: Column(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              RButton(
                2,
                width: triggerSize,
                onPressed: (value) => bridge.emitReport(.r2, value),
              ),
              RButton(
                1,
                width: triggerSize,
                onPressed: (value) => bridge.emitReport(.r1, value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CenterControls extends StatelessWidget {
  const CenterControls({super.key});

  @override
  Widget build(BuildContext context) {
    final Size(:width) = context.watch<AppSize>();
    final bridge = context.read<BridgeCubit>();
    return Row(
      spacing: 16,
      mainAxisAlignment: .center,
      children: [
        SelectButton(onPressed: (value) => bridge.emitReport(.select, value)),
        PSButton(
          size: width / 12,
          onPressed: (value) => bridge.emitReport(.ps, value),
        ),
        StartButton(onPressed: (value) => bridge.emitReport(.start, value)),
      ],
    );
  }
}

class Dualshock3Widget extends StatelessWidget {
  const Dualshock3Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: .symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: .max,
        children: [
          Triggers(),
          Expanded(
            child: Row(
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .stretch,
              children: [LeftPad(), RightPad()],
            ),
          ),
          CenterControls(),
        ],
      ),
    );
  }
}
