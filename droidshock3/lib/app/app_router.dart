import 'package:auto_route/auto_route.dart';

import '/common/common.dart';
import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter with AppLogger {
  static final _pageTransition = RouteType.custom(
    duration: 250.ms,
    reverseDuration: 250.ms,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubicEmphasized,
        reverseCurve: Curves.easeInOutCubicEmphasized,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .13),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: .9, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );

  static final _bottomSheetTransition = RouteType.custom(
    opaque: false,
    barrierDismissible: true,
    barrierColor: const Color(0x77000000),
    duration: 250.ms,
    reverseDuration: 250.ms,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1), // slide up from bottom
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );

  @override
  RouteType get defaultRouteType => _pageTransition;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/bootstrap', initial: true, page: BootstrapRoute.page),
    AutoRoute(
      path: '/app',
      page: AppShellRoute.page,
      children: [
        AutoRoute(path: 'home', page: HomeRoute.page, initial: true),
        AutoRoute(
          path: 'select-gamepad',
          page: GamepadSelectorRoute.page,
          type: _bottomSheetTransition,
        ),
        AutoRoute(
          path: 'remap-gamepad',
          page: GamepadRemapRoute.page,
          type: _bottomSheetTransition,
        ),
        AutoRoute(path: 'battery-saver', page: BatterySaverRoute.page),
        AutoRoute(path: 'bridge', page: BridgeRoute.page),
        RedirectRoute(path: '*', redirectTo: 'home'),
      ],
    ),
  ];
}

extension RoutingExtension on BuildContext {
  void navToBridgePage() => router.navigate(const BridgeRoute());

  void navToBatterySaver() => router.navigate(const BatterySaverRoute());

  void navToGamepadSelector() => router.navigate(const GamepadSelectorRoute());

  void navToGamepadRemap() => router.navigate(const GamepadRemapRoute());
}
