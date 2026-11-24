import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:protocol/protocol.dart';
import 'package:protocol/logger.dart';
import 'package:protocol/utils.dart';
import 'package:usb_gadget/usb_gadget.dart';

import 'board/board.dart';
import 'reports/feature_reports.dart';

(Gadget gadget, Dualshock3 dualshock3) createDualshock3([
  String name = 'ds3_gadget',
]) {
  final dualshock3 = Dualshock3();
  final gadget = Gadget(
    name: name,
    id: Id(vendor: 0x054C, product: 0x0268),
    class_: .interfaceSpecific(),
    strings: {
      .enUS: .new(
        manufacturer: 'Sony Computer Entertainment Inc.',
        product: 'PLAYSTATION(R)3 Controller',
        serialNumber: 'SN00000000',
      ),
    },
    configs: [
      .new(
        description: 'DualShock 3',
        selfPowered: true,
        remoteWakeup: true,
        maxPower: .new(500),
        functions: [dualshock3],
      ),
    ],
  );
  return (gadget, dualshock3);
}

/// Emulates a Sony DualShock 3 controller using FunctionFS.
final class Dualshock3 extends HidFunctionFs with Ds3Logger implements Board {
  Dualshock3({List<int>? deviceAddr, List<int>? pairedAddr, int? serialnumber})
    : eeprom = Eeprom(),
      revision = 0x8A,
      serialnumber = serialnumber ?? 0x01D88151,
      deviceAddr = .fromList(
        deviceAddr ?? [0x9E, 0xE8, 0x28, 0x31, 0xC7, 0x33],
      ),
      pairedAddr = .fromList(
        pairedAddr ?? [0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
      ),
      input = InputReport(),
      output = OutputReport(),
      super(
        name: 'dualshock3',
        reportDescriptor: const [
          0x05, 0x01, 0x09, 0x04, 0xA1, 0x01, 0xA1, 0x02, 0x85, 0x01, 0x75, //
          0x08, 0x95, 0x01, 0x15, 0x00, 0x26, 0xFF, 0x00, 0x81, 0x03, 0x75, //
          0x01, 0x95, 0x13, 0x15, 0x00, 0x25, 0x01, 0x35, 0x00, 0x45, 0x01, //
          0x05, 0x09, 0x19, 0x01, 0x29, 0x13, 0x81, 0x02, 0x75, 0x01, 0x95, //
          0x0D, 0x06, 0x00, 0xFF, 0x81, 0x03, 0x15, 0x00, 0x26, 0xFF, 0x00, //
          0x05, 0x01, 0x09, 0x01, 0xA1, 0x00, 0x75, 0x08, 0x95, 0x04, 0x35, //
          0x00, 0x46, 0xFF, 0x00, 0x09, 0x30, 0x09, 0x31, 0x09, 0x32, 0x09, //
          0x35, 0x81, 0x02, 0xC0, 0x05, 0x01, 0x75, 0x08, 0x95, 0x27, 0x09, //
          0x01, 0x81, 0x02, 0x75, 0x08, 0x95, 0x30, 0x09, 0x01, 0x91, 0x02, //
          0x75, 0x08, 0x95, 0x30, 0x09, 0x01, 0xB1, 0x02, 0xC0, 0xA1, 0x02, //
          0x85, 0x02, 0x75, 0x08, 0x95, 0x30, 0x09, 0x01, 0xB1, 0x02, 0xC0, //
          0xA1, 0x02, 0x85, 0xEE, 0x75, 0x08, 0x95, 0x30, 0x09, 0x01, 0xB1, //
          0x02, 0xC0, 0xA1, 0x02, 0x85, 0xEF, 0x75, 0x08, 0x95, 0x30, 0x09, //
          0x01, 0xB1, 0x02, 0xC0, 0xC0, //
        ],
        config: const .bidirectional(
          pollInterval: .new(milliseconds: 8),
          reportInterval: .new(milliseconds: 8),
        ),
      ) {
    features = FeatureReport(this);
  }

  @override
  final Uint8List deviceAddr;

  @override
  final Uint8List pairedAddr;

  @override
  final Eeprom eeprom;

  @override
  final int revision;

  @override
  final int serialnumber;

  final InputReport input;
  final OutputReport output;
  late final FeatureReport features;

  /// Called after each output report from the host updates [output].
  void Function(OutputReport output)? onOutputReport;

  StreamSubscription<void>? _epInSub;
  StreamSubscription<Uint8List>? _epOutSub;

  /// Whether the host has the function enabled and input streaming on.
  bool get _streaming => state == .enabled && features.inputStreamingEnabled;

  @override
  void onEnable() {
    _epOutSub ??= epOut.stream().listen(
      (bytes) => switch (bytes) {
        [0x01, ...final data] => _onOutputReport(data),
        _ => log?.warn('Received unrecognized output report: ${bytes.xxd()}'),
      },
      onError: onError,
      onDone: () => _epOutSub = null,
    );
    _stream();
  }

  @override
  void onResume() => _stream();

  /// The streams end on their own; dropped here so that an enable right
  /// after doesn't find the old ones.
  @override
  void onDisable() {
    unawaited(_epOutSub?.cancel());
    unawaited(_epInSub?.cancel());
    _epOutSub = null;
    _epInSub = null;
  }

  /// Sends input reports while [_streaming]. The host turns streaming on
  /// with a SET_REPORT after enabling the function, so this also runs after
  /// each SET_REPORT.
  void _stream() {
    if (!_streaming) return;
    _epInSub ??= epIn
        .writeWhile(
          condition: () => _streaming,
          data: () => [0x01, ...input.bytes],
          interval: config.reportInterval,
        )
        .asStream()
        .listen(null, onError: onError, onDone: () => _epInSub = null);
  }

  void _onOutputReport(List<int> data) {
    output.update(data);
    onOutputReport?.call(output);
  }

  @override
  List<int>? onGetReport(HidReportType type, int reportId) {
    return switch ((type, reportId)) {
      (.input, 0x01) => [0x01, ...input.bytes],
      (.feature, 0x01) => features.getControllerInfo(),
      (.feature, 0xF1) => features.getEepromBlock(),
      (.feature, 0xF2) => features.getDeviceInfo(),
      (.feature, 0xF5) => features.getPairingInfo(),
      (.feature, 0xEF) => features.getSensorConfig(),
      (.feature, 0xF7) => features.getSensorParameters(),
      (.feature, 0xF8) => features.getSensorStatus(),
      _ => _unhandled('GET_REPORT', type, reportId),
    };
  }

  @override
  void onSetReport(HidReportType type, int reportId, Uint8List data) {
    switch ((type, reportId)) {
      case (.output, 0x01):
        // Starts with the report ID, like reports on the OUT endpoint.
        _onOutputReport(switch (data) {
          [0x01, ...final report] => report,
          _ => data,
        });
      case (.feature, 0xEF):
        features.setSensorState(data);
      case (.feature, 0xF1):
        features.setEepromAccess(data);
      case (.feature, 0xF4):
        features.handleCommand(data);
      case (.feature, 0xF5):
        features.setPairedHost(data);
      default:
        _unhandled('SET_REPORT', type, reportId);
    }
    _stream(); // EF and F4 can turn input streaming on.
  }

  /// Logs an unsupported request, which the host then sees stalled.
  Null _unhandled(String request, HidReportType type, int reportId) {
    log?.warn('Unhandled $request: type=${type.name}, id=${reportId.toHex()}');
    return null;
  }

  @override
  void onError(Object error, StackTrace stack) =>
      stderr.writeln('[Dualshock3] $error\n$stack');
}
