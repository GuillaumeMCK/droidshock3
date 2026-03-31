import '/bridge/bridge_cubit.dart';
import '/common/common.dart';

class PlayerId extends HookWidget {
  const PlayerId({super.key = const Key('player_id')});

  static const _active = ColoredBox(
    color: Color(0xFFFF0000),
    child: SizedBox.square(dimension: 8),
  );

  static const _inactive = ColoredBox(
    color: Color(0x1DFF0000),
    child: SizedBox.square(dimension: 8),
  );

  static const List<bool> _off = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme) = context.theme;
    final bridge = context.read<BridgeCubit>();
    final leds = useState<List<bool>>(_off);
    usePeriodic(250.ms, () {
      leds.value = bridge.ledStates;
    });
    return DefaultTextStyle(
      style: textTheme.muted.mono.xxs,
      child: Row(
        mainAxisSize: .min,
        spacing: 16,
        children: [
          for (var i = 0; i < 4; i++)
            Column(
              spacing: 4,
              mainAxisSize: .min,
              children: [
                Text('${i + 1}'),
                AnimatedSwitcher(
                  duration: 150.ms,
                  child: leds.value[i] ? _active : _inactive,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
