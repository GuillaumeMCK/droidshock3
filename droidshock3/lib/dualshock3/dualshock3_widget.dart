import '/app/app_shell.dart';

import 'package:lucide_icons_flutter/lucide_icons_200.dart';

import '/bridge/bridge_cubit.dart';
import '/common/common.dart';
import '/dualshock3/conversion.dart';
import '/home/home_cubit.dart';

import 'widgets/display/pad.dart';
import 'widgets/inputs/inputs.dart';

class RightPad extends StatelessWidget {
  const RightPad({super.key});

  @override
  Widget build(BuildContext context) {
    final Size(:width) = context.watch<AppSize>();
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
            onPressed: (value) =>
                context.read<BridgeCubit>().emitReport(.r3, value),
            onPositionChanged: (value) => context.read<BridgeCubit>()
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
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.triangle, value),
                ),
              ),
              Align(
                alignment: .centerLeft,
                child: SquareButton(
                  size: btnSize,
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.square, value),
                ),
              ),
              Align(
                alignment: .centerRight,
                child: CircleButton(
                  size: btnSize,
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.circle, value),
                ),
              ),
              Align(
                alignment: .bottomCenter,
                child: CrossButton(
                  size: btnSize,
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.cross, value),
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
            onPressed: (value) =>
                context.read<BridgeCubit>().emitReport(.l3, value),
            onPositionChanged: (value) => context.read<BridgeCubit>()
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
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.up, value),
                ),
              ),
              Align(
                alignment: .centerLeft,
                child: DirectionButton.right(
                  size: btnSize,
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.left, value),
                ),
              ),
              Align(
                alignment: .centerRight,
                child: DirectionButton.left(
                  size: btnSize,
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.right, value),
                ),
              ),
              Align(
                alignment: .bottomCenter,
                child: DirectionButton.up(
                  size: btnSize,
                  onPressed: (value) =>
                      context.read<BridgeCubit>().emitReport(.down, value),
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
                onPressed: (value) =>
                    context.read<BridgeCubit>().emitReport(.l2, value),
              ),
              LButton(
                1,
                width: triggerSize,
                onPressed: (value) =>
                    context.read<BridgeCubit>().emitReport(.l1, value),
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
                onPressed: (value) =>
                    context.read<BridgeCubit>().emitReport(.r2, value),
              ),
              RButton(
                1,
                width: triggerSize,
                onPressed: (value) =>
                    context.read<BridgeCubit>().emitReport(.r1, value),
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
    return Row(
      spacing: 16,
      mainAxisAlignment: .center,
      children: [
        SelectButton(
          onPressed: (value) =>
              context.read<BridgeCubit>().emitReport(.select, value),
        ),
        PSButton(
          size: width / 12,
          onPressed: (value) =>
              context.read<BridgeCubit>().emitReport(.ps, value),
        ),
        StartButton(
          onPressed: (value) =>
              context.read<BridgeCubit>().emitReport(.start, value),
        ),
      ],
    );
  }
}

class MotionButton extends StatelessWidget {
  const MotionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final cubit = context.watch<HomeCubit>();
    final isActive = cubit.state.motionEnabled;

    return ShadIconButton.ghost(
      iconSize: 21,
      onPressed: () => cubit.toggleMotion(),
      icon: Icon(
        LucideIcons200.rotate3d,
        color: isActive ? colorScheme.primary : colorScheme.muted,
      ),
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
          MotionButton(),
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
