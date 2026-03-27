import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '/bridge/bridge_cubit.dart';
import '/gamepad/gamepads_cubit.dart';
import '/bootstrap/bootstrap_cubit.dart';
import '/common/hooks.dart';
import '/common/styles/styles.dart';
import '/common/widgets/utils/no_scroll_behavior.dart';
import '/injection.dart';
import 'app_router.dart';
import 'app_system_ui.dart';
import 'app_router.gr.dart';

class AppWidget extends HookWidget {
  const AppWidget({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final router = useMemoized(AppRouter.new);
    final bootstrap = useBlocState(getIt<BootstrapCubit>());

    usePostFrameEffect(
      () => switch (bootstrap) {
        BootstrapLoaded() => router.replace(const AppShellRoute()),
        _ => null,
      },
      keys: [bootstrap],
    );

    return ShadApp.router(
      title: title,
      themeMode: .system,
      theme: lightTheme,
      darkTheme: darkTheme,
      scrollBehavior: NoScrollBehavior(),
      routerConfig: router.config(),
      locale: const Locale('en', 'US'),
      localizationsDelegates: const [GlobalWidgetsLocalizations.delegate],
      shortcuts: {...WidgetsApp.defaultShortcuts},
      actions: {...WidgetsApp.defaultActions},
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<BridgeCubit>()),
          BlocProvider.value(value: getIt<GamepadsCubit>()),
        ],
        child: AppSystemUI(child: child!),
      ),
    );
  }
}
