import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../shared_widgets/layout/gap.dart';
import '/common/common.dart';
import 'bridge_cubit.dart';

@RoutePage()
class BridgePage extends HookWidget {
  const BridgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.theme.colorScheme.background,
      child: Column(
        children: [
          Expanded(child: _BridgeLogView()),
          Padding(
            padding: .symmetric(horizontal: 16, vertical: 8),
            child: _BridgeControls(),
          ),
        ],
      ),
    );
  }
}

class _BridgeControls extends HookWidget {
  const _BridgeControls();

  static bool _pending = true;

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final cubit = useMemoized(context.read<BridgeCubit>);
    final state = useBlocState(cubit);

    final pending = useState(_pending);

    useEffect(() {
      _pending = pending.value;
      return null;
    }, [pending.value]);

    return ShadCard(
      radius: .circular(50),
      child: Column(
        mainAxisSize: .min,
        spacing: 16,
        children: [
          ?switch (state) {
            BridgeError(:final error, :final stackTrace) => Text(
              '$error\n$stackTrace',
              style: textTheme.muted.xs,
            ),
            BridgeClosed(previousState: final BridgeError status) => Text(
              '${status.error}\n${status.stackTrace}',
              style: textTheme.muted.xs,
            ),
            _ => null,
          },
          Row(
            spacing: 8,
            children: [
              ShadButton(
                enabled: pending.value,
                onPressed: () async {
                  try {
                    pending.value = false;
                    await cubit.shutdown();
                    await cubit.setup();
                    await cubit.connect();
                  } finally {
                    pending.value = true;
                  }
                },
                leading: Icon(
                  LucideIcons.rotateCcw,
                  color: colorScheme.destructiveForeground,
                  size: 14,
                ),
                child: ShadBadge.destructive(
                  backgroundColor: colorScheme.card.alphaGhost,
                  child: Text(state.type.name.toUpperCase()),
                ),
              ),
              ShadButton.destructive(
                onPressed: () async {
                  try {
                    pending.value = false;
                    await cubit.shutdown();
                  } finally {
                    pending.value = true;
                  }
                },
                decoration: ShadDecoration(border: .all(radius: .circular(12))),
                leading: Icon(
                  LucideIcons.powerOff,
                  color: colorScheme.destructiveForeground,
                  size: 14,
                ),
              ),
              Expanded(
                child: ShadButton.ghost(
                  onPressed: context.router.pop,
                  leading: Icon(LucideIcons.chevronLeft),
                  child: const Text('Back'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BridgeLogView extends HookWidget {
  const _BridgeLogView();

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:textTheme) = context.theme;
    final controller = useScrollController();
    final file = useMemoized(() => File(BridgeCubit.logPath));
    final logs = useStream(
      file.watch().asyncMap((event) async {
        switch (event.type) {
          case FileSystemEvent.create || FileSystemEvent.modify:
            return file.readAsString();
        }
      }),
      initialData: file.existsSync() ? file.readAsStringSync() : null,
    );

    useEffect(() {
      if (logs.hasData && controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: 200.ms,
          curve: Curves.easeInOutCubicEmphasized,
        );
      }
      return null;
    }, [logs.data]);

    return SingleChildScrollView(
      padding: .symmetric(horizontal: 4, vertical: 8),
      controller: controller,
      clipBehavior: .none,
      child: switch (logs) {
        AsyncSnapshot(error: null, hasData: false) => SizedBox.shrink(),
        AsyncSnapshot(hasData: true, data: final log) => Text(
          log ?? '',
          style: textTheme.muted.mono.sm,
        ),
        AsyncSnapshot(error: final Object e) => switch (e) {
          PathNotFoundException(:final path) => Text(
            'Log file not found at $path',
            style: textTheme.muted.xs,
          ),
          _ => Text('Error reading log file: $e', style: textTheme.muted.xs),
        },
      },
    );
  }
}
