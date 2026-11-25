import 'package:protocol/process.dart';

export 'package:protocol/process.dart' show CommandException;

/// Runs [script] as root, and returns its stdout.
///
/// The script goes to su's stdin: every su takes that, Magisk, KernelSU and
/// APatch as well as AOSP's, which has no `-c`.
///
/// Throws a [CommandException] if it exits with an error or is still running
/// after [timeout].
Future<String> su(
  String script, {
  Duration timeout = const Duration(seconds: 10),
}) => runCommand('su', [], input: '$script\nexit\n', timeout: timeout);
