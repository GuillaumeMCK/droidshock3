part of 'logger.dart';

abstract class IPrinter {
  void onLog(LogRecord record);
}

@Singleton(as: IPrinter, env: [Environment.dev, Environment.test])
final class DebugPrinter extends IPrinter {
  static const _levelColors = {
    LogLevel.debug: '\x1B[90m',
    LogLevel.info: '\x1B[38;5;33m',
    LogLevel.warn: '\x1B[38;5;214m',
    LogLevel.error: '\x1B[38;5;196m',
  };

  static const _resetColor = '\x1B[0m';

  @override
  void onLog(LogRecord record) {
    final color = levelColor(record.level);
    final time = record.time.toIso8601String().substring(11, 23);
    final type = '[${record.level.name.toUpperCase()}]\t$_resetColor';
    stdout.writeln('$color$time $type(${record.loggerName}) ${record.message}');
    if (record.error != null) {
      stderr.writeln('$color${record.error}$_resetColor');
    }
    if (record.stackTrace != null) {
      stderr.writeln('$color${record.stackTrace}$_resetColor');
    }
  }

  String levelColor(LogLevel level) => _levelColors[level]!;
}

@Singleton(as: IPrinter, env: [Environment.prod])
final class ReleasePrinter extends IPrinter {
  @override
  void onLog(LogRecord record) {}
}
