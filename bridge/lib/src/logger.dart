import 'package:ffsds3/ffsds3.dart';

mixin BridgeLogger implements ILogger {
  @override
  Logger get log => const Logger('Bridge');
}
