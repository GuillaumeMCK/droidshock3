part of 'logger.dart';

mixin BootstrapLogger implements ILogger {
  @override
  Logger? get log => isProd ? null : Logger('$runtimeType');
}

mixin ServiceLogger implements ILogger {
  @override
  Logger? get log => isProd ? null : Logger('$runtimeType');
}

mixin AppLogger implements ILogger {
  @override
  Logger? get log => isProd ? null : Logger('$runtimeType');
}
