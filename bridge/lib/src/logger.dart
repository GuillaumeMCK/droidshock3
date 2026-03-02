import 'package:ffsds3/ffsds3.dart';

mixin BridgeLogger implements ILogger {
  Logger get log => Logger('Bridge');
}
