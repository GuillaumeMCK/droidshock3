part of 'logger.dart';

abstract class IPrinter {
  void onLog(LogRecord record);
}

@Singleton(as: IPrinter, env: [Environment.dev, Environment.test])
final class DebugPrinter extends IPrinter {
  DebugPrinter() {
    _initLogFile();
  }

  late final IOSink _sink;

  static const _levelColors = {
    LogLevel.debug: '\x1B[90m',
    LogLevel.info: '\x1B[38;5;33m',
    LogLevel.warning: '\x1B[38;5;214m',
    LogLevel.error: '\x1B[38;5;196m',
  };

  static const _resetColor = '\x1B[0m';

  Future<void> _initLogFile() async {
    final dir = await getApplicationCacheDirectory();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/app_$date.log');
    await file.create(recursive: true);
    _sink = file.openWrite(mode: FileMode.append);
  }

  @override
  void onLog(LogRecord record) {
    final time = record.time.toIso8601String().substring(11, 23);
    final level = '[${record.level.name.toUpperCase()}]';

    // CLI
    final color = _levelColors[record.level]!;
    debugPrint(
      '$color$time $level\t$_resetColor(${record.loggerName}) ${record.message}',
    );
    if (record.stackTrace != null) {
      final date = record.time.toIso8601String().substring(0, 10);
      debugPrint('$color$date\t-\t${record.stackTrace}$_resetColor');
    }

    // File
    _sink.write('$time $level\t(${record.loggerName}) ${record.message}\n');
    if (record.stackTrace != null) {
      final date = record.time.toIso8601String().substring(0, 10);
      _sink.write('$date\t-\t${record.stackTrace}\n');
    }
  }

  Future<void> dispose() async {
    await _sink.flush();
    await _sink.close();
  }
}

@Singleton(as: IPrinter, env: [Environment.prod])
final class ReleasePrinter extends IPrinter {
  @override
  void onLog(LogRecord record) {}
}
