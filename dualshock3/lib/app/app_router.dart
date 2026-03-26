import 'package:auto_route/auto_route.dart';

import '/common/common.dart';
import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter with AppLogger {
  @override
  final RouteType defaultRouteType = .custom(
    duration: 150.ms,
    reverseDuration: 150.ms,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubicEmphasized,
        reverseCurve: Curves.easeInOutCubicEmphasized,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .13),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: ScaleTransition(
          scale: Tween<double>(begin: .9, end: 1).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );

  @override
  final List<AutoRoute> routes = [
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
  void gotoBridgePage() => router.navigate(const BridgeRoute());
}
