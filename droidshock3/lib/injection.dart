import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

export 'package:injectable/injectable.dart';

GetIt get getIt => GetIt.instance;

@InjectableInit()
void configureInjection(String environment) {
  assert(
    [Environment.dev, Environment.prod, Environment.test].contains(environment),
    'Unknown environment: $environment',
  );
  getIt.init(environment: environment);
}
