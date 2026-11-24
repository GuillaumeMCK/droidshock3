import 'logger.dart';

mixin Ds3Logger implements ILogger {
  @override
  late final Logger? log = kLogEnabled ? .new('$runtimeType') : null;
}
