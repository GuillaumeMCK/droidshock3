import 'package:auto_route/auto_route.dart';

import '/common/common.dart';
import '/env.dart';
import 'app_guard.dart';
import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter with AppLogger {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    DefaultRoute(path: '/bootstrap', initial: true, page: BootstrapRoute.page),
    DefaultRoute(
      path: '/app',
      page: AppShellRoute.page,
      guards: [AppGuard()],
      children: [
        DefaultRoute(path: 'home', page: HomeRoute.page),
        DefaultRoute(path: 'bridge', page: BridgeRoute.page),
        RedirectRoute(path: '*', redirectTo: 'home'),
      ],
    ),
  ];
}

class DefaultRoute extends CustomRoute<void> {
  DefaultRoute({
    super.path,
    super.initial,
    required super.page,
    super.children,
    super.maintainState,
    super.opaque,
    super.guards,
    super.enablePredictiveBackGesture,
  }) : super(
         transitionsBuilder: _customTransition,
         duration: 100.ms,
         reverseDuration: 100.ms,
       );

  static Widget _customTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Effects.engagingCurve,
      reverseCurve: Effects.engagingCurve.flipped,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.03),
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
  }
}

extension RoutingExtension on BuildContext {
  void pushBridgeLogView() => router.push(const BridgeRoute());
}
