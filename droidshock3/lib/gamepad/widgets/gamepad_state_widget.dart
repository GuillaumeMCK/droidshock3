import 'package:droidshock3/app/app_router.dart';

import '/app/app_shell.dart' show AppSize;
import '/common/common.dart';

import '../gamepads_cubit.dart';

final class GamepadStateWidget extends HookWidget {
  const GamepadStateWidget({super.key = const .new('gamepad-state-widget')});

  @override
  Widget build(BuildContext context) {
    final Size(:height, :width) = context.watch<AppSize>();
    final gamepads = useBlocState(context.read<GamepadsCubit>());

    usePostFrameEffect(() {
      if (gamepads.length > 1) {
        context.navToGamepadSelector();
      }
    }, keys: [gamepads.length]);

    return SizedBox(
      height: height / 4,
      width: width / 1.25,
      child: switch (gamepads.length) {
        <= 0 => _NoGamepadsWidget(),
        >= 1 => _SelectedGamepad(),
        _ => throw AssertionError('Unexpected number of gamepads: $gamepads'),
      },
    );
  }
}

final class _SelectedGamepad extends HookWidget {
  const _SelectedGamepad();

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final gamepad = useBlocState(context.read<GamepadsCubit>()).selected;

    final (color1, color2) = useMemoized(
      () => (colorScheme.primary.shiftLightness(), colorScheme.primary),
      [colorScheme],
    );

    return Column(
      spacing: 8,
      mainAxisAlignment: .center,
      children: [
        Row(
          spacing: 8,
          children: [
            Text('${gamepad?.name}', style: textTheme.lead),
            ShadBadge.outline(child: Text('${gamepad?.id}')),
            Spacer(),
            RepeatingAnimationBuilder(
              animatable: Tween<double>(begin: 0, end: 1),
              duration: 500.ms,
              repeatMode: .reverse,
              builder: (_, value, _) => Icon(
                LucideIcons.bluetoothConnected,
                color: Color.lerp(color1, color2, value),
                size: 21,
              ),
            ),
          ],
        ),
        Text(
          'Your gamepad is connected! '
          'You may need to remap your inputs before use.',
          style: textTheme.muted,
        ),
        Padding(
          padding: .only(top: 8),
          child: ShadButton.outline(
            size: .sm,
            expands: true,
            child: Text('Remap Inputs', textAlign: .center),
            onPressed: () => context.navToGamepadRemap(),
          ),
        ),
      ],
    );
  }
}

final class _NoGamepadsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme, :colorScheme) = context.theme;
    return Column(
      spacing: 8,
      mainAxisAlignment: .center,
      children: [
        Row(
          spacing: 4,
          mainAxisAlignment: .spaceBetween,
          children: [
            Text('No gamepads found', style: textTheme.list),
            Icon(
                  LucideIcons.bluetoothSearching,
                  color: colorScheme.background,
                  size: 21,
                )
                .animate(autoPlay: true, onComplete: (c) => c.repeat())
                .shimmer(color: colorScheme.primary, duration: 2.seconds),
          ],
        ),
        Text(
          'Pair a Bluetooth controller to your phone and this app will '
          'relay its inputs as a DualShock3 over USB.',
          style: textTheme.muted,
        ),
      ],
    );
  }
}
