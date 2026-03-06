import 'package:auto_route/auto_route.dart';

import '/common/common.dart';
import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter with AppLogger {
  @override
  RouteType defaultRouteType = .custom(
    duration: 2.5.seconds,
    reverseDuration: 2.5.seconds,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubicEmphasized.flipped,
        reverseCurve: Curves.easeInOutCubicEmphasized,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .13),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curvedAnimation),
          child: ScaleTransition(
            scale: Tween<double>(begin: .9, end: 1).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );

  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/bootstrap', initial: true, page: BootstrapRoute.page),
    AutoRoute(
      path: '/app',
      page: AppShellRoute.page,
      children: [
        AutoRoute(path: 'home', page: HomeRoute.page, initial: true),
        AutoRoute(path: 'bridge', page: BridgeRoute.page),
        RedirectRoute(path: '*', redirectTo: 'home'),
      ],
    ),
  ];
}

extension RoutingExtension on BuildContext {
  void pushBridgeLogView() => router.push(const BridgeRoute());
}
