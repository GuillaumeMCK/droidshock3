import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '/common/common.dart';
import '/env.dart';

part 'mixin.dart';

part 'printer.dart';

void configureLogger() {
  Logger.init(logPrinter: getIt<IPrinter>());
}

class Logger {
  const Logger(this.name);

  static IPrinter? _logPrinter;

  static int _logLevel = LogLevel.debug.level;

  static const root = Logger('root');

  static void init({required IPrinter logPrinter, int? level}) {
    _logPrinter = logPrinter;
    if (level != null) {
      _logLevel = level;
    }
  }

  final String name;

  static bool logPlatformDispatcherError(Object error, StackTrace stackTrace) {
    root.error('Uncaught error in PlatformDispatcher', error, stackTrace);
    return true;
  }

  void debug(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.debug, message, error, stack);
  }

  void info(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.info, message, error, stack);
  }

  void warning(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.warning, message, error, stack);
  }

  void error(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message, error, stack);
  }

  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    if (level.level < _logLevel) {
      return;
    }
    _logPrinter?.onLog(
      LogRecord(
        loggerName: name,
        level: level,
        message: message,
        error: error,
        stackTrace: stack,
      ),
    );
  }
}

enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3);

  const LogLevel(this.level);

  final int level;
}

final class LogRecord {
  LogRecord({
    required this.loggerName,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final String loggerName;
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime time = DateTime.now();
}

abstract class ILogger {
  Logger? get log;
}
