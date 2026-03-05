import 'common/common.dart' show Environment;

const String env = .fromEnvironment('ENV', defaultValue: Environment.prod);

const bool isProd = env == Environment.prod;
const bool isDev = env == Environment.dev;
const bool isTest = env == Environment.test;
