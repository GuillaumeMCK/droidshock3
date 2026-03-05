import 'package:auto_route/auto_route.dart';

import '/bootstrap/bootstrap_cubit.dart';
import '../injection.dart';
import 'app_router.gr.dart';

class AppGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final bootstrapCubit = getIt<BootstrapCubit>();
    final state = bootstrapCubit.state;

    if (state is! BootstrapLoaded) {
      router
        ..popUntilRoot()
        ..replace(const BootstrapRoute());
    } else {
      resolver.next();
    }
  }
}
