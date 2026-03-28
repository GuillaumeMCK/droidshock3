import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:ffsds3/ffsds3.dart';
import 'package:gamepads/gamepads.dart';

import '/app/app_shell.dart';
import '/common/widgets/display/progress_ring.dart';
import '/common/common.dart';
import '/gamepad/gamepads_cubit.dart';

@RoutePage()
class GamepadRemapPage extends HookWidget {
  const GamepadRemapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme) = context.theme;
    final Size(:height) = context.watch<AppSize>();
    final gamepads = useBlocState(context.read<GamepadsCubit>());

    final AsyncSnapshot(:data) = useStream(
      gamepads.selected?.onPressed ?? Stream.empty(),
    );

    return ShadSheetInheritedWidget(
      side: .bottom,
      child: ShadSheet(
        title: const Text('Remap Inputs'),
        description: const Text('Press buttons on your gamepad to remap them'),
        scrollable: true,
        child: SizedBox(
          height: height * .4,
          child: Center(child: Column(children: [Text('$data')])),
        ),
      ),
    );
  }
}

//
// class _MapInput extends HookWidget {
//   final DS3Input target;
//   final String? gamepadId;
//
//   const _MapInput(this.target, this.gamepadId);
//
//   @override
//   Widget build(BuildContext context) {
//     final active = useState(false);
//     final button = useState<GamepadButton?>(null);
//     final axis = useState<GamepadAxis?>(null);
//     final pressed = useState(false);
//
//     useStreamListener(Gamepads.normalizedEvents, (event) {
//       if (gamepadId != event.gamepadId) return;
//       print(event);
//
//       if (event.button == defaultMapping[target]) {
//         button.value = event.button;
//         pressed.value = event.value != 0;
//       }
//     });
//
//     return ShadButton.outline(
//       size: .lg,
//       onPressed: () => active.value = !active.value,
//       trailing: ShadBadge.secondary(child: Text(target.name)),
//       decoration: ShadDecoration(
//         border: .all(
//           color: pressed.value
//               ? context.colorScheme.primary
//               : context.colorScheme.muted,
//         ),
//       ),
//       child: DefaultTextStyle(
//         style: context.textTheme.small.noHeight,
//         child: switch (active.value) {
//           true when (button.value != null) => Text(button.value!.name),
//           true when (axis.value != null) => Text(axis.value!.name),
//           true => ProgressRing(size: 14),
//           false => Text(defaultMapping[target]!.name),
//         },
//       ),
//     );
//   }
// }
