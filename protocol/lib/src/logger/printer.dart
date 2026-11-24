import 'dart:io';

import 'logger.dart';

abstract class IPrinter {
  void onLog(LogRecord record);
}

final class DefaultPrinter extends IPrinter {
  static const _levelColors = {
    LogLevel.debug: '\x1b[90m',
    LogLevel.info: '\x1b[38;5;33m',
    LogLevel.warning: '\x1b[38;5;214m',
    LogLevel.success: '\x1b[38;5;34m',
    LogLevel.error: '\x1b[38;5;196m',
    LogLevel.fatal: '\x1b[38;5;160m',
  };

  static const _rst = '\x1b[0m';

  String levelColor(LogLevel level) => _levelColors[level]!;

  @override
  void onLog(LogRecord record) {
    final buffer = StringBuffer();
    if (kLogColors) {
      buffer.write(levelColor(record.level));
    }
    buffer.write('[${record.level}]');
    if (kLogColors) {
      buffer.write(_rst);
    }
    buffer.write(' [${record.loggerName}] ${record.message}');
    stdout.writeln(buffer.toString());
    if (record.error != null) {
      stderr.writeln(record.error);
    }
    if (record.stackTrace != null) {
      stderr.writeln(record.stackTrace);
    }
  }
}
