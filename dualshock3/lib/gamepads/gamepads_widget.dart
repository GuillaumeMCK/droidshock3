import '/common/common.dart';

import 'gamepads_cubit.dart';

final class GamepadsWidget extends HookWidget {
  GamepadsWidget({super.key = const .new('gamepads-widget')});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme, :colorScheme) = context.theme;
    final gamepads = useBlocState(context.read<GamepadsCubit>());

    return Padding(
      padding: .symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: .min,
        children: [
          if (gamepads.isEmpty)
            Padding(
              padding: .symmetric(horizontal: 4, vertical: 8),
              child: Row(
                spacing: 4,
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text('No gamepads found', style: textTheme.list),
                  ShadButton.ghost(
                    size: .sm,
                    trailing: Icon(LucideIcons.bluetoothSearching500, size: 14),
                  ),
                ],
              ),
            )
          else
            for (final gamepad in gamepads)
              Padding(
                padding: .symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text(
                      '${gamepad.name} (${gamepad.id})',
                      style: textTheme.list,
                    ),
                    const Spacer(),
                    ShadButton.ghost(
                      size: .sm,
                      onPressed: () {},
                      trailing: Icon(
                        LucideIcons.chevronsRight500,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      child: Text(
                        'Use',
                        style: textTheme.xs.semibold.withColor(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          Padding(
            padding: .only(top: 8, left: 4, right: 2, bottom: 4),
            child: Text(
              'Pair a Bluetooth controller to your phone and this app will '
              'relay its inputs as a DualShock3 controller over USB.',
              style: textTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}
