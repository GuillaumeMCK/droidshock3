import 'dart:io';

export 'core.dart';
export 'mixin.dart';
export 'printer.dart';

// Read at runtime: `dart build cli` takes no `-D` defines.
final bool kLogEnabled = Platform.environment['FFSDS3_LOG'] == 'true';
final bool kLogColors = Platform.environment['FFSDS3_LOG_COLORS'] == 'true';
final int kLogLevel =
    int.tryParse(Platform.environment['FFSDS3_LOG_LEVEL'] ?? '') ?? 3;
