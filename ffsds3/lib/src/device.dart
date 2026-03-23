import 'dart:async';
import 'dart:typed_data';

import 'package:usb_gadget/usb_gadget.dart';

import 'board/board.dart';
import 'reports/feature_reports.dart';
import 'reports/input_report.dart';
import 'reports/output_report.dart';

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
        serialnumber: 'SN00000000',
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
final class Dualshock3 extends HIDFunctionFs implements Board {
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
        reportDescriptor: .fromList([
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
        ]),
        speeds: {.fullSpeed, .highSpeed},
        config: const .bidirectional(
          pollInterval: .new(milliseconds: 1),
          reportInterval: .new(milliseconds: 1),
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

  StreamSubscription<int>? _epInSub;
  StreamSubscription<Uint8List>? _epOutSub;

  @override
  Future<void> onEnable() async {
    super.onEnable();
    _epInSub ??= epIn.writeWhile(
      condition: () => features.inputStreamingEnabled && state == .enabled,
      data: () => input.bytes,
    );
    _epOutSub ??= epOut.stream.listen(
      (bytes) => switch (bytes) {
        [0x01, ...final data] when data.length == 48 => output.update(data),
        _ => log?.warn('Received unrecognized output report: ${bytes.xxd()}'),
      },
    );
  }

  @override
  Future<void> onDisable() async {
    await release(partial: true);
    super.onDisable();
  }

  @override
  Future<void> release({bool partial = false}) async {
    if (isReleased) return;
    await [?_epOutSub?.cancel(), ?_epOutSub?.cancel()].wait;
    _epOutSub = null;
    _epInSub = null;
    if (partial) return;
    await super.release();
  }

  @override
  Uint8List onGetReport(HIDReportType type, int reportId) {
    return switch ((type, reportId)) {
      (.input, 0x01) => input.bytes,
      (.feature, 0x01) => features.getControllerInfo(),
      (.feature, 0xF1) => features.getEepromBlock(),
      (.feature, 0xF2) => features.getDeviceInfo(),
      (.feature, 0xF5) => features.getPairingInfo(),
      (.feature, 0xEF) => features.getSensorConfig(),
      (.feature, 0xF7) => features.getSensorParameters(),
      (.feature, 0xF8) => features.getSensorStatus(),
      _ => throw UnsupportedError(
        'Unhandled GET_REPORT: type=${type.name}, id=${reportId.toHex()}',
      ),
    };
  }

  @override
  void onSetReport(HIDReportType type, int reportId, Uint8List data) {
    return switch ((type, reportId)) {
      (.output, 0x01) => output.update(data),
      (.feature, 0xEF) => features.setSensorState(data),
      (.feature, 0xF1) => features.setEepromAccess(data),
      (.feature, 0xF4) => features.handleCommand(data),
      (.feature, 0xF5) => features.setPairedHost(data),
      _ => throw UnsupportedError(
        'Unhandled SET_REPORT: type=${type.name}, id=${reportId.toHex()}',
      ),
    };
  }
}
