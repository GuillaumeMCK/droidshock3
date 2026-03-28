import 'package:auto_route/auto_route.dart';

import '/common/common.dart';
import 'gamepads_cubit.dart';

@RoutePage()
class GamepadSelectorPage extends HookWidget {
  const GamepadSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gamepads = useBlocState(context.read<GamepadsCubit>());

    usePostFrameEffect(() {
      if (gamepads.isEmpty) {
        context.back();
      }
    }, keys: [gamepads]);

    return ShadSheetInheritedWidget(
      side: .bottom,
      child: ShadSheet(
        title: const Text('Select a gamepad'),
        description: const Text(
          'You have multiple gamepads connected, which one do you want to use?',
        ),
        child: Padding(
          padding: const .all(16),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final gamepad in gamepads)
                ShadButton.secondary(
                  size: .lg,
                  onPressed: () {
                    context.read<GamepadsCubit>().pair(gamepad);
                    context.router.back();
                  },
                  leading: ShadBadge(child: Text(gamepad.id)),
                  child: Text(gamepad.name),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
