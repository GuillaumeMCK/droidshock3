import 'dart:async';
import 'dart:io';

import 'package:ffsds3/ffsds3.dart';
import 'package:protocol/process.dart';

/// The Android side of the bridge: what it needs from the system, done here
/// in Dart rather than in the app's shell script, so it's checked and logged
/// the same way on every device.
abstract final class Android {
  static const Logger _log = Logger('Bridge');

  /// Where configfs is mounted when Android hasn't: Android mounts it at
  /// /config, which usb_gadget finds in /proc/mounts.
  static const _configfs = '/sys/kernel/config';

  static Future<String> getprop(String name) async =>
      (await runCommand('getprop', [name])).trim();

  static Future<void> setprop(String name, String value) =>
      runCommand('setprop', [name, value]);

  /// What a bug report needs to know about the device, one `name: value`
  /// per line.
  static Future<String> describe() async {
    Future<String> prop(String name) => _orUnknown(getprop(name));
    final List<String> configfs = _configfsMounts();
    final String? gadgets = configfs.isEmpty
        ? null
        : '${configfs.first}/usb_gadget';
    final Map<String, String> lines = {
      'Device':
          '${await prop('ro.product.manufacturer')} '
          '${await prop('ro.product.model')}',
      'Android':
          '${await prop('ro.build.version.release')} '
          '(SDK ${await prop('ro.build.version.sdk')})',
      'Kernel': _read('/proc/sys/kernel/osrelease'),
      'Root': await _rootManager(),
      'SELinux': switch (_read('/sys/fs/selinux/enforce')) {
        '1' => 'enforcing',
        '0' => 'permissive',
        final String other => other,
      },
      'configfs': configfs.isEmpty ? 'not mounted' : configfs.join(', '),
      // Its module loads when a gadget first uses it.
      'FunctionFS': _read('/proc/filesystems').contains('\tfunctionfs')
          ? 'loaded'
          : 'not loaded yet',
      'USB controllers': _list('/sys/class/udc').join(', '),
      'Gadgets': gadgets == null
          ? '-'
          : _list(gadgets)
                .map(
                  (String name) =>
                      '$name (UDC: ${_read('$gadgets/$name/UDC')})',
                )
                .join(', '),
      'USB props':
          'config=${await prop('sys.usb.config')}, '
          'state=${await prop('sys.usb.state')}, '
          'persist=${await prop('persist.sys.usb.config')}, '
          'controller=${await prop('sys.usb.controller')}',
    };
    return lines.entries
        .map((MapEntry<String, String> e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  /// Mounts configfs if Android hasn't, anywhere.
  static Future<void> mountConfigfs() async {
    if (_configfsMounts().isNotEmpty) return;
    _log.info('Mounting configfs at $_configfs');
    await runCommand('mount', ['-t', 'configfs', 'none', _configfs]);
  }

  /// Moves the bridge out of the process group (cgroup) it was started in.
  ///
  /// Android kills a process group as a whole: adbd's when USB stops adb, and
  /// with some root managers the app's when it's stopped. The bridge must
  /// outlive both to give USB back; its client watchdog stops it instead.
  static void leaveProcessGroup() {
    for (final String procs in [
      '/sys/fs/cgroup/cgroup.procs', // cgroup v2
      '/acct/cgroup.procs', // cgroup v1
    ]) {
      try {
        File(procs).writeAsStringSync('$pid');
        _log.info('Moved to the root process group ($procs)');
        return;
      } on FileSystemException {
        continue;
      }
    }
    _log.warn(
      'Could not leave the process group: stopping its owner stops '
      'the bridge',
    );
  }

  /// Where configfs is mounted, from /proc/mounts.
  static List<String> _configfsMounts() => [
    for (final String line in _read('/proc/mounts').split('\n'))
      if (line.split(' ') case [_, final String path, 'configfs', ...]) path,
  ];

  /// Takes the USB controller from Android's own gadget (adb, MTP...), and
  /// returns the `sys.usb.config` to give it back with [restoreUsb].
  static Future<String> takeUsb() async {
    String config = await getprop('persist.sys.usb.config');
    if (config.isEmpty) config = await getprop('sys.usb.config');
    await setprop('sys.usb.config', 'none');
    // Android unbinds its gadget asynchronously.
    final Stopwatch waited = Stopwatch()..start();
    while (await getprop('sys.usb.state') != 'none') {
      if (waited.elapsed > const Duration(seconds: 3)) {
        _log.warn('sys.usb.state still not none after 3 s');
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _log.info('Took USB from Android (was $config)');
    return config;
  }

  static Future<void> restoreUsb(String config) async {
    try {
      await setprop('sys.usb.config', config);
      _log.info('Gave USB back to Android ($config)');
    } on CommandException catch (err, st) {
      _log.error('Failed to restore USB config:', err, st);
    }
  }

  /// Stops the bridge [processFile] names, left running by a previous
  /// start: asks it to (SIGTERM, which it cleans up on), then forces it.
  static Future<void> stopPrevious(File processFile, String exeDir) async {
    if (!processFile.existsSync()) return;
    final int? previous = int.tryParse(
      processFile.readAsStringSync().split(':').first,
    );
    // Only a bridge: the PID may have been reused since.
    final bool running =
        previous != null &&
        previous != pid &&
        _read('/proc/$previous/cmdline').contains(exeDir);
    if (running) {
      _log.warn('Stopping the previous bridge (PID $previous)');
      Process.killPid(previous, ProcessSignal.sigterm);
      if (!await _exited(previous, const Duration(seconds: 3))) {
        _log.warn('It ignored SIGTERM: killing it');
        Process.killPid(previous, ProcessSignal.sigkill);
        await _exited(previous, const Duration(seconds: 1));
      }
    }
    if (processFile.existsSync()) processFile.deleteSync();
  }

  static Future<bool> _exited(int pid, Duration timeout) async {
    final Stopwatch waited = Stopwatch()..start();
    while (Directory('/proc/$pid').existsSync()) {
      if (waited.elapsed > timeout) return false;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return true;
  }

  static Future<String> _rootManager() async {
    final String name = switch ((
      Directory('/data/adb/magisk').existsSync(),
      Directory('/data/adb/ksu').existsSync(),
      Directory('/data/adb/ap').existsSync(),
    )) {
      (true, _, _) => 'Magisk',
      (_, true, _) => 'KernelSU',
      (_, _, true) => 'APatch',
      _ => 'unknown',
    };
    final String version = await _orUnknown(
      runCommand('su', ['-v'], timeout: const Duration(seconds: 2)),
    );
    return '$name (su -v: ${version.trim()})';
  }

  /// [value], or `?` if it fails: a description is best-effort.
  static Future<String> _orUnknown(Future<String> value) async {
    try {
      return await value;
    } on CommandException {
      return '?';
    }
  }

  /// The trimmed contents of [path], or `-` if it can't be read.
  static String _read(String path) {
    try {
      return File(path).readAsStringSync().trim();
    } on FileSystemException {
      return '-';
    }
  }

  /// The names in [path], or `-` if it can't be listed.
  static List<String> _list(String path) {
    try {
      return [
        for (final FileSystemEntity e in Directory(path).listSync())
          e.uri.pathSegments.lastWhere((String s) => s.isNotEmpty),
      ]..sort();
    } on FileSystemException {
      return ['-'];
    }
  }
}
