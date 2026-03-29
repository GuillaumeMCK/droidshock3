import 'package:auto_route/auto_route.dart';
import 'package:ffsds3/ffsds3.dart';

import '/app/app_shell.dart';
import '/common/common.dart';
import '/gamepad/gamepads_cubit.dart';

@RoutePage()
class GamepadRemapPage extends HookWidget {
  const GamepadRemapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme, :colorScheme) = context.theme;
    final Size(:height, :width) = context.watch<AppSize>();
    final gamepads = useBlocState(context.read<GamepadsCubit>());

    final first = useState<DS3Input?>(null);
    final second = useState<DS3Input?>(null);

    usePostFrameEffect(() {
      if (gamepads.selected == null) context.back();
    }, keys: [gamepads]);

    useStreamListener(
      gamepads.selected?.onPressed ?? const Stream.empty(),
      (data) {
        final (input, _) = data;
        if (first.value != null && second.value != null) {
          first.value = null;
          second.value = null;
        }

        if (first.value == null) {
          first.value = input;
        } else if (first.value != input) {
          second.value = input;
        }
      },
      keys: [gamepads.selected?.id],
    );

    void onSwap() {
      final (f, s) = (first.value, second.value);
      if (f != null && s != null) gamepads.selected?.remap(f, s);
      first.value = null;
      second.value = null;
    }

    void onRestore() {
      gamepads.selected?.restoreMap();
      first.value = null;
      second.value = null;
    }

    final canSwap = first.value != null && second.value != null;
    final hasAny = first.value != null || second.value != null;

    return ShadSheetInheritedWidget(
      side: ShadSheetSide.bottom,
      child: ShadSheet(
        title: const Text('Remap Inputs'),
        description: const Text(
          'Press a button to select it, then press another to swap.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: onRestore,
            child: const Text('Restore'),
          ),
          ShadButton(
            enabled: hasAny,
            onPressed: canSwap ? onSwap : null,
            child: const Text('Swap'),
          ),
        ],
        child: _SwapDisplay(
          height: height,
          width: width,
          textTheme: textTheme,
          colorScheme: colorScheme,
          first: first.value,
          second: second.value,
        ),
      ),
    );
  }
}

class _SwapDisplay extends StatelessWidget {
  const _SwapDisplay({
    required this.height,
    required this.width,
    required this.textTheme,
    required this.colorScheme,
    required this.first,
    required this.second,
  });

  final double height;
  final double width;
  final ShadTextTheme textTheme;
  final ShadColorScheme colorScheme;
  final DS3Input? first;
  final DS3Input? second;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * .30,
      child: Row(
        children: [
          Expanded(
            child: Text(
              first?.name.toUpperCase() ?? '?',
              style: textTheme.h3,
              textAlign: TextAlign.center,
            ),
          ),
          Icon(
            LucideIcons.arrowLeftRight300,
            size: width / 6,
            color: colorScheme.muted,
          ),
          Expanded(
            child: Text(
              second?.name.toUpperCase() ?? '?',
              style: textTheme.h3,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
