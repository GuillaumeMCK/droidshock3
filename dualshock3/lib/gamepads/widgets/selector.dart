import 'package:dualshock3/common/common.dart';
import 'package:dualshock3/shared_widgets/layout/constrained_list_view.dart';

import '/shared_widgets/layout/gap.dart';
import '../gamepads_cubit.dart';

class GamepadsSelector extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme, :colorScheme) = context.theme;
    final gamepads = useBlocState(context.read<GamepadsCubit>());
    return Padding(
      padding: .symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 4,
        children: [
          Transform.translate(
            offset: Offset(-16, 0),
            child: Row(
              spacing: 4,
              children: [
                Icon(LucideIcons.bluetooth, size: 21),
                Text('Bluetooth Gamepad', style: textTheme.h3),
              ],
            ),
          ),
          Text(
            'Connect your gamepad via Bluetooth from android settings.'
            ' Then, it will appear here and you can start using it.',
            style: textTheme.muted,
          ),
          Gap(8),
          ShadCard(
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: gamepads.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: .symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      spacing: 4,
                      children: [
                        Text('${gamepads[i]?.id}', style: textTheme.list),
                        Text('${gamepads[i]?.name}', style: textTheme.list),
                        Text(
                          '${gamepads[i]?.productId}',
                          style: textTheme.list,
                        ),
                        Text('${gamepads[i]?.vendorId}', style: textTheme.list),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
