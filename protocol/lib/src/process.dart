import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A command that failed, timed out, or couldn't start.
final class CommandException implements Exception {
  const CommandException(this.command, this.reason, {this.output = ''});

  final String command;
  final String reason;

  /// What it wrote to stdout and stderr.
  final String output;

  @override
  String toString() => [
    '$reason: $command',
    if (output.trim().isNotEmpty) output.trim(),
  ].join('\n');
}

/// Runs [executable], with [input] on its stdin, and returns its stdout once
/// it exits with 0.
///
/// Its exit code decides, not what it writes to stderr: tools and su
/// implementations differ in what they print. Throws a [CommandException],
/// with the output, when it exits with another code, or when it's still
/// running after [timeout], which kills it.
Future<String> runCommand(
  String executable,
  List<String> arguments, {
  String? input,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final String command = [
    executable,
    ...arguments,
    if (input != null) '<<< ${input.trim().split('\n').join('; ')}',
  ].join(' ');
  final Process process;
  try {
    process = await Process.start(executable, arguments);
  } on ProcessException catch (err) {
    throw CommandException(command, 'Failed to start (${err.message})');
  }
  // A child left running in the background may keep the pipes open: don't
  // wait for them past the exit.
  Future<String> read(Stream<List<int>> stream) => stream
      .transform(utf8.decoder)
      .join()
      .timeout(const Duration(seconds: 1), onTimeout: () => '');
  final Future<String> stdout = read(process.stdout);
  final Future<String> stderr = read(process.stderr);
  if (input != null) process.stdin.write(input);
  try {
    await process.stdin.close();
  } on Object catch (_) {
    // It exited before reading it all: its exit code tells.
  }

  final int? exitCode = await process.exitCode
      .then<int?>((int code) => code)
      .timeout(timeout, onTimeout: () => null);
  if (exitCode == null) process.kill(ProcessSignal.sigkill);
  final String out = await stdout;
  final String output = [out, await stderr].join('\n');
  return switch (exitCode) {
    0 => out,
    null => throw CommandException(
      command,
      'Timed out after ${timeout.inSeconds} s',
      output: output,
    ),
    final int code => throw CommandException(
      command,
      'Exited with $code',
      output: output,
    ),
  };
}
