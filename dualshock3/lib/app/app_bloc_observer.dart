import 'package:bloc/bloc.dart';

import '/common/logger/logger.dart';

final class AppBlocObserver extends BlocObserver with AppLogger {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log?.error('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    log?.debug('onEvent(${bloc.runtimeType}, $event)');
    super.onEvent(bloc, event);
  }
}
