import 'dart:typed_data';
import 'package:usb_gadget/usb_gadget.dart';

import '../board/board.dart';

/// Sub-commands for Feature Report `F4` (controller control).
///
/// Every `F4` payload must begin with the prefix byte `0x42`, followed by
/// one of the command bytes below.
///
/// ```dart
/// // Enable input streaming
/// handler.setF4Command(Uint8List.fromList([0x42, 0x02]));
/// ```
enum F4Command {
  /// Stop automatic input report streaming (`0x01`).
  ///
  /// The controller ceases sending periodic HID input reports.
  disableInputStreaming,

  /// Start automatic input report streaming (`0x02`).
  ///
  /// The controller sends input report `0x01` approximately every 10 ms
  /// while the PS button is held.
  enableInputStreaming,

  /// Include motion sensor data in input reports (`0x03`).
  ///
  /// Accelerometer and gyroscope readings are appended to input report
  /// `0x01`. Required for motion-control support in compatible games.
  enableOutputMotionSensors,

  /// Enter active mode on PS3 boot (`0x0C`).
  ///
  /// Sent by the PS3 during startup to bring the controller online.
  startupController,

  /// Power off on PS3 shutdown (`0x0B`).
  ///
  /// Sent by the PS3 during shutdown; the controller should enter a low-power
  /// or idle state.
  shutdownController,

  /// Reset runtime state to factory defaults (`0x04`).
  ///
  /// Clears streaming mode, sensor configuration, and other volatile state.
  /// Persistent data such as MAC addresses and EEPROM calibration values are
  /// not affected.
  restartController;

  /// Returns the [F4Command] for the given raw [byte].
  ///
  /// Throws [ArgumentError] if [byte] does not map to a known command.
  factory F4Command.fromByte(int byte) => switch (byte) {
    0x01 => .disableInputStreaming,
    0x02 => .enableInputStreaming,
    0x03 => .enableOutputMotionSensors,
    0x04 => .restartController,
    0x0B => .shutdownController,
    0x0C => .startupController,
    _ => throw ArgumentError('Unrecognized F4 command: ${byte.toHex()}'),
  };
}

/// Handles HID GET_FEATURE / SET_FEATURE requests for a virtual DualShock 3.
///
/// Encapsulates the persistent configuration state of a single controller
/// instance, including EEPROM contents, sensor calibration data, and runtime
/// mode flags. EEPROM storage is delegated to the [Board.eeprom] instance and
/// can be accessed directly for operations outside the HID protocol.
///
/// Runtime flags are kept in [state], a 4-byte buffer:
///
/// | Index | Meaning |
/// |-------|---------|
/// | 0     | Reserved (typically `0x00`) |
/// | 1     | Streaming mode (`0x00` = off, `0x01` = on, `0x03` = with sensors) |
/// | 2     | Sensor calibration offset into EEPROM bank 1 (typically `0x90`) |
/// | 3     | Sensitivity mode |

final class FeatureReport with USBGadgetLogger {
  /// Creates a feature report handler backed by [board].
  FeatureReport(this._board) : state = Uint8List(4);

  /// Shared board state (MAC addresses, EEPROM, serial number, revision).
  final Board _board;

  /// 4-byte runtime configuration buffer.
  ///
  /// Mutated by [handleCommand] and [setSensorState]; read by
  /// [getSensorConfig], [getSensorStatus], and [inputStreamingEnabled].
  final Uint8List state;

  /// Whether the controller is currently sending periodic input reports.
  bool get inputStreamingEnabled => state[1] == 0x01;

  // ---------------------------------------------------------------------------
  // GET_FEATURE responses
  // ---------------------------------------------------------------------------

  /// Returns the **`01` – Controller Information** feature report.
  ///
  /// The 64-byte response contains:
  /// - Byte 1: Report ID (`0x01`)
  /// - Bytes 2–4: Controller type and firmware bytes (EEPROM bank 0, `0x01–0x04`)
  /// - Bytes 5–48: Stick calibration preview (EEPROM bank 0, `0x60–0x8B`)
  Uint8List getControllerInfo() {
    log?.debug('Controller information report');
    final response = Uint8List(64)
      ..[0] = 0x00
      ..[1] = 0x01
      ..setAll(0x2, _board.eeprom.read(bank: 0, 0x01, 0x04))
      ..setAll(0x5, _board.eeprom.read(bank: 0, 0x60, 0x2C));
    log?.debug(response.xxd());
    return response;
  }

  /// Returns the next **`F1` – EEPROM Block** feature report.
  ///
  /// Reads the 16-byte block currently addressed by the EEPROM pointer
  /// (set via [setEepromAccess] with [EepromCommand.pointer]). The address
  /// is automatically aligned to [Eeprom.blockSize] boundaries.
  ///
  /// Response layout:
  /// - Bytes 0–4: Fixed header (`0x57, 0x01, 0xFF, 0xFF, 0x10`)
  /// - Bytes 5–20: 16 bytes of EEPROM data
  Uint8List getEepromBlock() {
    final block = _board.eeprom.readBlock();
    final result = Uint8List(64)
      ..setAll(0, const [0x57, 0x01, 0xFF, 0xFF, 0x10])
      ..setAll(5, block);
    log?.debug(
      'EEPROM read from bank ${_board.eeprom.currentBank}, '
      'address ${_board.eeprom.currentAddress.toHex()}: ${result.xxd()}',
    );
    return result;
  }

  /// Returns the **`F2` – Device Information** feature report.
  ///
  /// Typically requested during initial USB enumeration. The 64-byte response
  /// contains:
  /// - Byte 0: Report ID (`0xF2`)
  /// - Bytes 1–2: Fixed (`0xFF, 0xFF`)
  /// - Bytes 4–9: Controller MAC address (reversed byte order)
  /// - Bytes 12–15: Serial number (little-endian `uint32`)
  /// - Byte 16: PCB revision
  /// - Bytes 17–47: Calibration block (EEPROM bank 0, `0x6C–0x8A`)
  Uint8List getDeviceInfo() {
    final response = Uint8List(64)
      ..[0] = 0xF2
      ..[1] = 0xFF
      ..[2] = 0xFF
      ..[3] = 0x00
      ..setAll(4, _board.deviceAddr.reversed)
      ..[10] = 0x00
      ..[11] = 0x03
      ..setAll(12, _board.serialnumber.toBytes(4, .little))
      ..[16] = _board.revision
      ..setAll(17, _board.eeprom.read(bank: 0, 0x6C, 0x1F));
    log?.debug('Device information report ${response.xxd()}');
    return response;
  }

  /// Returns the **`F5` – Pairing Information** feature report.
  ///
  /// Reports which host Bluetooth address the controller will reconnect to
  /// wirelessly. The 64-byte response contains:
  /// - Byte 0: `0x01`
  /// - Bytes 2–7: Paired host MAC address
  /// - Bytes 8–9: First two bytes of controller MAC (reversed)
  /// - Bytes 12–15: Serial number (little-endian `uint32`)
  /// - Byte 16: PCB revision
  /// - Bytes 17–47: Calibration block (EEPROM bank 0, `0x6C–0x8A`)
  Uint8List getPairingInfo() {
    final r = Uint8List(64)
      ..[0] = 0x01
      ..[1] = 0x00
      ..setAll(2, _board.pairedAddr)
      ..setAll(8, _board.deviceAddr.sublist(0, 2).reversed)
      ..[10] = 0x00
      ..[11] = 0x03
      ..setAll(0x0C, _board.serialnumber.toBytes(4, .little))
      ..[16] = _board.revision
      ..setAll(17, _board.eeprom.read(bank: 0, 0x6C, 0x1F));
    log?.debug('Pairing information report ${r.xxd()}');
    return r;
  }

  /// Returns the **`EF` – Extended Sensor Configuration** feature report.
  ///
  /// The 64-byte response contains:
  /// - Byte 1: Report ID (`0xEF`)
  /// - Bytes 2–5: Configuration marker (EEPROM bank 0, `0x01–0x04`)
  /// - Bytes 5–8: Current [state] bytes
  /// - Bytes `0x11`–`0x20`: Motion sensor calibration — 16 bytes from EEPROM
  ///   bank 1 at the offset held in `state[2]` (typically `0x90`)
  /// - Byte `0x30`: Fixed footer (`0x05`)
  ///
  /// The calibration block contains 16-bit signed accelerometer and gyroscope
  /// offset/gain values.
  Uint8List getSensorConfig() {
    final sensorOffset = state[2];
    final r = Uint8List(64)
      ..[1] = 0xEF
      ..setAll(0x02, _board.eeprom.read(bank: 0, 0x01, 4))
      ..setAll(0x05, state)
      ..setAll(0x11, _board.eeprom.read(bank: 1, sensorOffset, 0x10))
      ..[0x30] = 0x5;
    log?.debug(
      'Extended sensor config with state: ${state.xxd()} and calibration: '
      '${r.sublist(0x11, 0x11 + 0x10).xxd()}',
    );
    return r;
  }

  /// Returns the **`F7` – Sensor Parameters** feature report.
  ///
  /// Contains additional sensor calibration values whose exact semantics are
  /// controller-specific. The 64-byte response contains:
  /// - Byte 7: `0xFF`
  /// - Bytes `0x11`–`0x24`: 20 calibration bytes (EEPROM bank 0, `0x8C–0x9F`)
  /// - Byte `0x30`: Fixed footer (`0x05`)
  Uint8List getSensorParameters() {
    final response = Uint8List(64)
      ..[0x7] = 0xFF
      ..setAll(0x11, _board.eeprom.read(bank: 0, 0x8C, 20))
      ..[0x30] = 0x5;
    log?.debug('Sensor parameters report: ${response.xxd()}');
    return response;
  }

  /// Returns the **`F8` – Sensor Status** feature report.
  ///
  /// The 64-byte response contains:
  /// - Bytes 0–3: Fixed header (`0x00, 0x01, 0x00, 0x00`)
  /// - Byte 4: Firmware low byte (EEPROM bank 0, offset `0x03`)
  /// - Bytes 5–8: Current [state] bytes
  /// - Bytes `0x11`–`0x20`: Motion sensor calibration — 16 bytes from EEPROM
  ///   bank 1 at the offset held in `state[2]`
  /// - Byte `0x30`: Fixed footer (`0x05`)
  Uint8List getSensorStatus() {
    final sensorOffset = state[2];
    final response = Uint8List(64)
      ..[0] = 0x00
      ..[1] = 0x01
      ..[2] = 0x00
      ..[3] = 0x00
      ..[4] = _board.eeprom.readByte(bank: 0, 0x03)
      ..setAll(5, state)
      ..setAll(0x11, _board.eeprom.read(bank: 1, sensorOffset, 0x10))
      ..[0x30] = 0x5;
    log?.debug('Sensor status report ${response.xxd()}');
    return response;
  }

  // ---------------------------------------------------------------------------
  // SET_FEATURE handlers
  // ---------------------------------------------------------------------------

  /// Handles an **`F1` – EEPROM Access** SET_FEATURE request.
  ///
  /// Either repositions the EEPROM read/write pointer or writes a 16-byte
  /// block, depending on the command byte in [data].
  ///
  /// Expected payload layout:
  ///
  /// | Byte | Field       | Notes                            |
  /// |------|-------------|----------------------------------|
  /// | 0    | –           | Ignored                          |
  /// | 1    | Command     | [EepromCommand] byte             |
  /// | 2–3  | –           | Ignored                          |
  /// | 4    | Bank        | `0` or `1`                       |
  /// | 5    | Address     | `0x00–0xFF`                      |
  /// | 6    | –           | Ignored                          |
  /// | 7+   | Write data  | 16 bytes; only for [EepromCommand.write] |
  ///
  /// Throws [ArgumentError] if [data] is too short or the command byte is
  /// unrecognised.
  void setEepromAccess(Uint8List data) {
    log?.debug('Received EEPROM command: ${data.xxd()}');

    switch (EepromCommand.fromByte(data[1])) {
      case .pointer:
        _board.eeprom.setPointer(data[4], data[5]);
        log?.debug(
          'Set EEPROM pointer to bank ${_board.eeprom.currentBank}, '
          'address ${_board.eeprom.currentAddress.toHex()}',
        );
      case .write:
        _board.eeprom.writeBlock(data.skip(7));
        log?.debug(
          'Write to EEPROM bank ${_board.eeprom.currentBank} at address '
          '${_board.eeprom.currentAddress.toHex()}: '
          '${data.sublist(7, 7 + Eeprom.blockSize).xxd()}',
        );
    }
  }

  /// Handles an **`F5` – Pairing** SET_FEATURE request.
  ///
  /// Writes the host Bluetooth MAC address from [data] into EEPROM bank 0 at
  /// offset `0x6C`. This address is returned by subsequent [getPairingInfo]
  /// calls and used by the controller for wireless reconnection.
  ///
  /// Expected payload layout:
  ///
  /// | Bytes | Field           |
  /// |-------|-----------------|
  /// | 0     | `0x01`          |
  /// | 1     | Reserved        |
  /// | 2–7   | Host MAC address |
  ///
  /// Throws [RangeError] if [data] is too short to contain a MAC address.
  void setPairedHost(Uint8List data) {
    _board.pairedAddr.setAll(0, data.sublist(2, 8));
    log?.info(
      'Paired host MAC address set to: '
      '${_board.pairedAddr.map((b) => b.toHex(prefix: false, padding: 2)).join(':')}'
      '${data.xxd()}',
    );
  }

  /// Handles an **`EF` – Extended Sensor Configuration** SET_FEATURE request.
  ///
  /// Copies bytes 4–7 of [data] into [state], updating the streaming mode,
  /// sensor calibration offset, and sensitivity values used by subsequent
  /// [getSensorConfig] and [getSensorStatus] calls.
  void setSensorState(Uint8List data) {
    state.setRange(0, 4, data.sublist(4, 8));
    log?.debug('Sensor state updated from: ${data.xxd()}');
  }

  /// Handles an **`F4` – Controller Control** SET_FEATURE request.
  ///
  /// Parses the [F4Command] from `data[1]` (after verifying the `0x42`
  /// prefix at `data[0]`) and updates [state] accordingly:
  ///
  /// | Command                    | Effect on `state`                      |
  /// |----------------------------|----------------------------------------|
  /// | [F4Command.enableInputStreaming]    | `state[1] = 0x01`       |
  /// | [F4Command.startupController]      | `state[1] = 0x01`       |
  /// | [F4Command.disableInputStreaming]  | `state[1] = 0x00`       |
  /// | [F4Command.enableOutputMotionSensors] | `state[1] = 0x03`   |
  /// | [F4Command.restartController]     | Zeroes all of [state] and resets the EEPROM pointer |
  /// | [F4Command.shutdownController]    | Zeroes all of [state] and resets the EEPROM pointer |
  ///
  /// Throws [ArgumentError] if `data[1]` is not a recognised command byte.
  void handleCommand(Uint8List data) {
    log?.debug('Received controller control command: ${data.xxd()}');
    switch (F4Command.fromByte(data[1])) {
      case .enableInputStreaming:
      case .startupController:
        log?.info('Enabling input streaming');
        state[1] = 0x01;
      case .disableInputStreaming:
        log?.info('Disabling input streaming');
        state[1] = 0x00;
      case .enableOutputMotionSensors:
        log?.info('Enabling motion sensor output');
        state[1] = 0x03;
      case .restartController:
      case .shutdownController:
        log?.info('Resetting controller state');
        state
          ..[0] = 0x00
          ..[1] = 0x00
          ..[2] = 0x00
          ..[3] = 0x00;
        _board.eeprom.setPointer(0, 0);
    }
  }
}
