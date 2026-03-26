import 'dart:math';

import 'package:auto_route/auto_route.dart';

import '/app/app_router.dart';
import '/gamepads/gamepads_widget.dart';
import '/dualshock3/display/player_id.dart';
import '/dualshock3/dualshock3_widget.dart';
import '/app/app_shell.dart';
import '/common/common.dart';

@RoutePage()
class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final constraints = context.watch<AppConstraints>();
    return Column(
      children: [
        Padding(
          padding: .all(24),
          child: Stack(
            clipBehavior: .none,
            children: [
              Align(
                alignment: .centerLeft,
                child: Transform.rotate(angle: pi, child: PlayerId()),
              ),
              Align(
                alignment: .bottomRight,
                child: Transform.rotate(
                  angle: pi,
                  child: Text(
                    'DROIDSHOCK 3',
                    style: textTheme.p.extraBold.noHeight.withColor(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ShadSeparator.horizontal(margin: .symmetric(vertical: 0)),
        Expanded(child: GamepadsWidget()),
        Dualshock3Widget(),
        SizedBox(height: 16),
        Padding(
          padding: .only(bottom: 16, top: 8),
          child: Align(
            alignment: .bottomCenter,
            child: Transform.rotate(
              angle: -.76,
              child: GestureDetector(
                onDoubleTap: () => context.gotoBridgePage(),
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
