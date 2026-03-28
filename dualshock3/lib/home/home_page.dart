import 'package:auto_route/auto_route.dart';

import '/app/app_router.dart';
import '/gamepad/widgets/gamepad_state_widget.dart';
import '/dualshock3/widgets/display/player_id.dart';
import '/dualshock3/dualshock3_widget.dart';
import '/app/app_shell.dart';
import '/common/common.dart';

@RoutePage()
class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final Size(:height) = context.watch<AppSize>();
    return Column(
      children: [
        Padding(
          padding: .all(24),
          child: Stack(
            clipBehavior: .none,
            children: [
              Align(alignment: .centerLeft, child: PlayerId()),
              Align(
                alignment: .bottomRight,
                child: Text(
                  'DROIDSHOCK 3',
                  style: textTheme.p.extraBold.noHeight.withColor(
                    colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ShadSeparator.horizontal(margin: .zero),
        GamepadStateWidget(),
        Gap(height / 12),
        Expanded(child: Dualshock3Widget()),
        Gap(16),
        Padding(
          padding: .only(bottom: 16, top: 8),
          child: Align(
            alignment: .bottomCenter,
            child: Transform.rotate(
              angle: -.76,
              child: GestureDetector(
                onDoubleTap: () => context.navToBridgePage(),
                child: Icon(
                  LucideIcons.usb,
                  color: colorScheme.muted,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        // Align(child: ConnectedGamepads()),
        // Align(alignment: .topRight),
      ],
    );
  }
}
