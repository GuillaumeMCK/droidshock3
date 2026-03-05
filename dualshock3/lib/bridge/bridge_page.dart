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
    final ShadThemeData(:textTheme, :colorScheme) = context.theme;

    return Stack(
      fit: .expand,
      children: [
        Positioned.fill(child: _BridgeLogView()),
        Align(alignment: .topCenter, child: _BridgeControls()),
        Align(
          alignment: .bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadIconButton(
              backgroundColor: colorScheme.secondary,
              icon: Icon(LucideIcons.x),
              onPressed: () => context.router.pop(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BridgeControls extends HookWidget {
  const _BridgeControls();

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme) = context.theme;
    final cubit = useMemoized(context.read<BridgeCubit>);
    final state = useBlocState(cubit);
    return Container(
      padding: .symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.background),
      child: Column(
        mainAxisSize: .min,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            mainAxisAlignment: .spaceBetween,
            children: [
              ShadBadge.outline(child: Text(state.type.name.toUpperCase())),
              ShadButton.destructive(
                onPressed: () => cubit.shutdown(),
                child: const Text('Shutdown'),
              ),
            ],
          ),
          if (state case BridgeError(:final error, :final stackTrace))
            Text('$error\n$stackTrace'),
          if (state case BridgeClosed(:final previousState))
            if (previousState case BridgeError(:final error, :final stackTrace))
              Text('$error\n$stackTrace'),
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
          curve: Effects.engagingCurve,
        );
      }
      return null;
    }, [logs.data]);

    return SingleChildScrollView(
      padding: .symmetric(horizontal: 4, vertical: 8),
      controller: controller,
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
