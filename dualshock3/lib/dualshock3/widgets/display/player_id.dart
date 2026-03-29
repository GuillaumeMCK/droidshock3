import 'package:ffsds3/ffsds3.dart';

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

  static const List<LedPattern> _off = [.off(), .off(), .off(), .off()];

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme) = context.theme;
    final bridge = context.read<BridgeCubit>();
    final ledPatterns = useState<List<LedPattern>>(_off);
    usePeriodic(250.ms, () {
      if (bridge.state is! BridgeConnected) {
        ledPatterns.value = _off;
        return;
      }
      ledPatterns.value = bridge.output.ledPatterns;
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
              children: [
                Text('${i + 1}'),
                switch (ledPatterns.value[i].isOff) {
                  true => _inactive,
                  false => _active,
                },
              ],
            ),
        ],
      ),
    );
  }
}
