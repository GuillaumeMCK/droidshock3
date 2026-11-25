export 'core.dart';
export 'mixin.dart';
export 'printer.dart';

// Set at compile time: tool/build_bridge.sh passes them to the bridge.
const bool kLogEnabled = bool.fromEnvironment('FFSDS3_LOG');
const bool kLogColors = bool.fromEnvironment('FFSDS3_LOG_COLORS');
const int kLogLevel = int.fromEnvironment(
  'FFSDS3_LOG_LEVEL',
  defaultValue: 3, // Warning.
);
