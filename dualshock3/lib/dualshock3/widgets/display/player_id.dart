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

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme) = context.theme;
    final data = useStream(
      .value((true, false, false, false)),
      initialData: (false, false, false, false),
    );
    return DefaultTextStyle(
      style: textTheme.muted.mono.xxs,
      child: Row(
        mainAxisSize: .min,
        spacing: 16,
        children: [
          Column(spacing: 4, children: [Text('1'), _active]),
          Column(spacing: 4, children: [Text('2'), _inactive]),
          Column(spacing: 4, children: [Text('3'), _inactive]),
          Column(spacing: 4, children: [Text('4'), _inactive]),
        ],
      ),
    );
  }
}
