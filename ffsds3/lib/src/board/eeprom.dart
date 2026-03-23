/// DualShock 3 EEPROM emulation.
///
/// **Bank 0 (0x00–0xFF):**
/// - 0x00–0x07: Controller type and firmware header
/// - 0x08–0x1F: Configuration data
/// - 0x20–0x27: Analog stick calibration values
/// - 0x28–0x5F: Additional calibration and settings
/// - 0x60–0x6B: Firmware version and stick center points
/// - 0x70–0x9F: Deadzone/gain configuration
/// - 0xB0–0xFF: Intensity/rumble lookup table (part 1)
///
/// **Bank 1 (0x00–0xFF):**
/// - 0x00–0x6F: Intensity/rumble lookup table (part 2)
/// - 0x70–0x7F: Duplicate controller header
/// - 0x80–0x8F: Additional configuration
/// - 0x90–0xAF: Motion sensor calibration (accel/gyro)
/// - 0xB0–0xEF: Reserved/configuration
/// - 0xF0–0xFF: Footer data
///
library;

import 'dart:typed_data';

import 'package:usb_gadget/usb_gadget.dart';

/// Command types carried in Feature Report **F1** (EEPROM access).
enum EepromCommand {
  /// Sets the bank and address pointer (0x0B).
  ///
  /// Prepares the controller for a subsequent GET_FEATURE by selecting which
  /// 16-byte block will be returned. Byte 4 of the report selects the bank,
  /// byte 5 selects the address.
  pointer,

  /// Writes a 16-byte block to the current pointer position (0x0A).
  ///
  /// Updates the EEPROM buffer at the current pointer with the payload
  /// provided in bytes 7+ of the SET_FEATURE request.
  write;

  factory EepromCommand.fromByte(int byte) => switch (byte) {
    0x0B => .pointer,
    0x0A => .write,
    _ => throw ArgumentError('Unrecognized EEPROM command: ${byte.toHex()}'),
  };
}

/// Emulated DualShock 3 EEPROM.
///
/// Holds both 256-byte banks, factory-initialised with the calibration data,
/// rumble lookup tables, and configuration blocks found in real hardware.
///
/// Typed region access ([read], [readByte], [write], [writeByte]) is provided
/// for direct manipulation outside the HID protocol. The F1 pointer operations
/// ([setPointer], [readBlock], [writeBlock]) mirror the hardware behaviour
/// exposed by Feature Report 0xF1.
///
/// ## Example
///
/// ```dart
/// final eeprom = Eeprom(firmware: 0x0C08, controllerType: 0x04);
///
/// // Read a named region
/// final stickCal = eeprom.read(bank: 0, address: 0x20, length: 16);
///
/// // Update a single byte
/// eeprom.writeByte(bank: 0, address: 0x03, value: 0x01);
///
/// // F1 pointer operations (used by the feature-report handler)
/// eeprom.setPointer(0, 0x20);
/// final block = eeprom.readBlock(); // 16-byte aligned block at 0x20
/// ```
final class Eeprom {
  /// Creates EEPROM content initialised with factory default values.
  ///
  /// Parameters:
  /// - [firmware]: Firmware version (16-bit). Stored at bank 0 offset 0x03
  ///   (low byte) and 0x60 (high byte).
  /// - [controllerType]: Controller type byte at bank 0 offset 0x01.
  ///   Use 0x04 for DualShock 3, 0x03 for Sixaxis.
  Eeprom({int firmware = 0x8A, int controllerType = 0x04})
    : bankA = Uint8List(256)
        // 0x00–0x03: Controller identification
        // [0x00] 0x01 constant, [0x01] controller type (0x03=Sixaxis, 0x04=DS3),
        // [0x02] 0x00 reserved,  [0x03] firmware low byte
        ..setAll(0x00, [0x01, controllerType, 0x00, firmware.byte(0)])
        // 0x08–0x1F: Configuration block — returned in Report 0x01 and EF report
        ..setAll(0x08, const [
          0xEE, 0x02, 0x00, 0x08, 0xEF, 0x04, 0x00, 0x08, //
          0x00, 0x00, 0x01, 0x64, 0x19, 0x01, 0x00, 0x64, //
          0x00, 0x01, 0x90, 0x00, 0x19, 0xFE, 0x00, 0x00, //
        ])
        // 0x20–0x2F: 4-pin analog stick center calibration (16 bytes)
        // First 8 bytes: LX, LY, RX, RY center values (16-bit little-endian)
        // Remaining 8 bytes: suffix/metadata
        // Note: all zeros at 0x20–0x24 indicates a 3-pin stick type
        ..setAll(0x20, const [
          0x01, 0xED, 0x01, 0xF7, 0x01, 0xDE, 0x01, 0xF8, // 0x20–0x27
          0x00, 0x01, 0x01, 0x60, 0x80, 0x20, 0x15, 0x01, // 0x28–0x2F
        ])
        // 0x30–0x5F: Extended calibration data
        // 0x46–0x4D: 3-pin calibration start
        // 0x4E–0x55: 3-pin calibration continued
        ..setAll(0x30, const [
          0xC7, 0x78, 0x7D, 0x81, 0x7C, 0x00, 0x1C, 0x7D, //
          0x83, 0x84, 0x85, 0x8B, 0x83, 0x10, 0xB0, 0x03, //
          0xFF, 0x00, 0x00, 0xFF, 0x44, 0x44, 0x00, 0x6E, //
          0x03, 0x92, 0x00, 0x6A, 0x03, 0x96, 0x00, 0x65, //
          0x03, 0x9B, 0x00, 0x5A, 0x03, 0xA6, 0x00, 0xFF, //
          0x77, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, //
        ])
        // 0x60: Firmware high byte (forms full version with byte 0x03)
        // 0x61–0x6B: Stick center and calibration values — returned in Report 0x01
        ..setAll(0x60, [
          firmware.byte(1), //
          0x01, 0x02, 0x18, 0x18, 0x18, 0x18, 0x09, 0x0A, //
          0x10, 0x11, 0x12, 0x13, 0x00, 0x00, 0x00, //
        ])
        // 0x70–0x9F: Deadzone/gain configuration — used in Report 0x01
        ..setAll(0x70, const [
          0x00, 0x04, 0x00, 0x02, 0x02, 0x02, 0x02, 0x00, //
          0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x00, 0x00, //
          0x04, 0x00, 0x01, 0x02, 0x07, 0x00, 0x17, 0x00, //
          0x00, 0x00, 0x00, 0x00, 0x02, 0x02, 0x02, 0x00, //
          0x03, 0x00, 0x00, 0x02, 0x00, 0x00, 0x02, 0x62, //
          0x01, 0x02, 0x01, 0x5E, 0x00, 0x32, 0x00, 0x00, //
        ])
        // 0xA0–0xAF: Configuration data
        ..setAll(0xA0, const [
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
          0x00, 0x00, 0x00, 0x00, 0x32, 0x20, 0x20, 0x02, //
        ])
        // 0xB0–0xFF: Rumble motor intensity lookup table — part 1 (80 bytes)
        // Maps input intensity values to motor PWM levels
        ..setAll(0xB0, const [
          0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x6C, //
          0x6C, 0x6C, 0x6C, 0x6C, 0x6D, 0x6D, 0x6E, 0x6E, //
          0x6F, 0x70, 0x71, 0x73, 0x75, 0x77, 0x79, 0x7B, //
          0x7D, 0x7F, 0x81, 0x83, 0x85, 0x87, 0x89, 0x8B, //
          0x8D, 0x8E, 0x90, 0x92, 0x93, 0x95, 0x97, 0x99, //
          0x9A, 0x9C, 0x9E, 0x9F, 0xA1, 0xA2, 0xA4, 0xA5, //
          0xA7, 0xA8, 0xAA, 0xAB, 0xAD, 0xAE, 0xB0, 0xB1, //
          0xB3, 0xB4, 0xB6, 0xB7, 0xB9, 0xBB, 0xBC, 0xBE, //
          0xBF, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC8, //
          0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCF, 0xD0, 0xD1, //
        ]),
      bankB = Uint8List(256)
        // 0x00–0x6F: Rumble motor intensity lookup table — part 2 (112 bytes)
        // Continuation from bank A 0xB0–0xFF
        ..setAll(0x00, const [
          0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, //
          0xDA, 0xDB, 0xDC, 0xDD, 0xDF, 0xE1, 0xE2, 0xE3, //
          0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, //
          0xEC, 0xED, 0xEE, 0xEF, 0xF0, 0xF1, 0xF2, 0xF3, //
          0xF4, 0xF4, 0xF5, 0xF5, 0xF6, 0xF6, 0xF7, 0xF7, //
          0xF7, 0xF8, 0xF8, 0xF8, 0xF9, 0xF9, 0xF9, 0xFA, //
          0xFA, 0xFA, 0xFA, 0xFB, 0xFB, 0xFB, 0xFB, 0xFB, //
          0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFD, 0xFD, 0xFD, //
          0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFE, 0xFE, //
          0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFE, //
          0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFF, 0xFF, //
          0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
          0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
          0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
        ])
        // 0x70–0x7F: Duplicate configuration data
        ..setAll(0x70, const [
          0x01, 0xC7, 0x78, 0x7D, 0x81, 0x7C, 0x00, 0x1C, //
          0x7D, 0x83, 0x84, 0x85, 0x8B, 0x83, 0x10, 0xB0, //
        ])
        // 0x80–0x8F: Configuration block
        ..setAll(0x80, const [
          0x03, 0xFF, 0x00, 0x00, 0xFF, 0x44, 0x44, 0x02, //
          0x6A, 0x02, 0x6E, 0x00, 0x00, 0x00, 0x00, 0x00, //
        ])
        // 0x90–0xAF: Motion sensor calibration data (32 bytes)
        // Used by Report 0xEF — accessed via state[2] offset
        // acc_x_bias/gain, acc_y_bias/gain, acc_z_bias/gain, gyro_z_offset
        // Format: 16-bit little-endian signed values
        ..setAll(0x90, const [
          0x00, 0x6E, 0x03, 0x92, 0x00, 0x6A, 0x03, 0x96, //
          0x00, 0x65, 0x03, 0x9B, 0x00, 0x5A, 0x03, 0xA6, //
          0x01, 0xFE, 0x01, 0x8B, 0x02, 0x00, 0x01, 0x8F, //
          0x02, 0x00, 0x01, 0x8D, 0x01, 0xF4, 0x00, 0x7D, //
        ])
        // 0xB0–0xBF: Configuration block
        ..setAll(0xB0, const [
          0x02, 0x6A, 0x02, 0x6E, 0x00, 0x00, 0x00, 0x00, //
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
        ])
        // 0xC0–0xCF: Configuration block
        ..setAll(0xC0, const [
          0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, //
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
        ])
        // 0xD0–0xEF: Reserved (zero-filled by Uint8List constructor)
        // 0xF0–0xFF: Footer block
        ..setAll(0xF0, const [
          0x20, 0x07, 0x09, 0x03, 0x00, 0x00, 0x22, 0x2F, //
          0x00, 0x01, 0x00, 0x00, 0x03, 0xBC, 0xB1, 0x09, //
        ]);

  /// EEPROM bank 0 (256 bytes).
  ///
  /// Contains controller header, configuration data, analog stick calibration,
  /// firmware version, deadzone settings, and the first part of the rumble
  /// intensity lookup table.
  ///
  /// Key regions:
  /// - 0x00–0x07: Controller type and header
  /// - 0x20–0x2F: Analog stick calibration
  /// - 0x60–0x6F: Firmware version and center points
  /// - 0xB0–0xFF: Rumble lookup table (part 1)
  final Uint8List bankA;

  /// EEPROM bank 1 (256 bytes).
  ///
  /// Contains the second part of the rumble intensity lookup table, duplicate
  /// configuration data, and motion sensor calibration values.
  ///
  /// Key regions:
  /// - 0x00–0x6F: Rumble lookup table (part 2)
  /// - 0x90–0xAF: Motion sensor calibration (accelerometer/gyroscope)
  final Uint8List bankB;

  // ---------------------------------------------------------------------------
  // F1 address pointer
  // ---------------------------------------------------------------------------

  /// Currently selected bank for F1 read/write operations (0 = [bankA], 1 = [bankB]).
  ///
  /// Set by [setPointer] and used by [readBlock] / [writeBlock].
  int currentBank = 0;

  /// Current byte offset within the selected bank for F1 operations (0–255).
  ///
  /// Set by [setPointer]. [readBlock] aligns this value down to the nearest
  /// [blockSize] boundary to match real hardware behaviour.
  int currentAddress = 0;

  /// Number of bytes per F1 GET_FEATURE transfer (16).
  ///
  /// Reads are always aligned to this boundary, so addresses 0x20–0x2F all
  /// return the same 16-byte block starting at 0x20.
  static const int blockSize = 0x10;

  // ---------------------------------------------------------------------------
  // Region access
  // ---------------------------------------------------------------------------

  /// Returns the raw [Uint8List] for [bank] (0 = [bankA], 1 = [bankB]).
  Uint8List bankData(int bank) {
    assert(bank == 0 || bank == 1, 'bank must be 0 or 1');
    return bank == 0 ? bankA : bankB;
  }

  /// Reads [length] bytes from [bank] starting at [address].
  ///
  /// Example:
  /// ```dart
  /// final calibration = eeprom.read(bank: 0, address: 0x20, length: 16);
  /// ```
  Uint8List read(int address, int length, {required int bank}) {
    assert(bank == 0 || bank == 1, 'bank must be 0 or 1');
    assert(address >= 0 && address <= 255, 'address must be 0–255');
    assert(length > 0, 'length must be positive');
    final src = bankData(bank);
    return Uint8List.fromList(src.sublist(address, address + length));
  }

  /// Reads a single byte from [bank] at [address].
  ///
  /// Example:
  /// ```dart
  /// final firmwareLow = eeprom.readByte(bank: 0, address: 0x03);
  /// ```
  int readByte(int address, {required int bank}) {
    assert(bank == 0 || bank == 1, 'bank must be 0 or 1');
    assert(address >= 0 && address <= 255, 'address must be 0–255');
    return bankData(bank)[address];
  }

  /// Writes [data] into [bank] starting at [address].
  ///
  /// Example:
  /// ```dart
  /// eeprom.write(bank: 1, address: 0x90, data: calibrationBytes);
  /// ```
  void write(int address, Iterable<int> data, {required int bank}) {
    assert(bank == 0 || bank == 1, 'bank must be 0 or 1');
    assert(address >= 0 && address <= 255, 'address must be 0–255');
    bankData(bank).setAll(address, data);
  }

  /// Overwrites a single byte in [bank] at [address] with [value].
  ///
  /// Example:
  /// ```dart
  /// eeprom.writeByte(bank: 0, address: 0x01, value: controllerType);
  /// ```
  void writeByte(int address, int value, {required int bank}) {
    assert(bank == 0 || bank == 1, 'bank must be 0 or 1');
    assert(address >= 0 && address <= 255, 'address must be 0–255');
    assert(value >= 0 && value <= 255, 'value must be 0–255');
    bankData(bank)[address] = value;
  }

  /// Sets the F1 bank and address pointer for subsequent [readBlock] /
  /// [writeBlock] calls.
  ///
  /// Matches the hardware behaviour triggered by an F1 SET_FEATURE with
  /// command byte 0x0B: byte 4 of the report selects the bank, byte 5 selects
  /// the address within that bank.
  void setPointer(int bank, int address) {
    assert(bank == 0 || bank == 1, 'bank must be 0 or 1');
    assert(address >= 0 && address <= 255, 'address must be 0–255');
    currentBank = bank;
    currentAddress = address;
  }

  /// Returns a 16-byte block from the bank/address set by [setPointer].
  ///
  /// The address is rounded down to the nearest [blockSize] boundary,
  /// matching real DS3 hardware where addresses 0x20–0x2F all return the
  /// block starting at 0x20.
  ///
  /// Returns a fresh [Uint8List] of length [blockSize].
  Uint8List readBlock() {
    final alignedAddr = (currentAddress ~/ blockSize) * blockSize;
    final src = bankData(currentBank);
    final result = Uint8List(blockSize);
    for (var i = 0; i < blockSize; i++) {
      result[i] = src[(alignedAddr + i) & 0xFF];
    }
    return result;
  }

  /// Writes [data] into the active bank at [currentAddress].
  ///
  /// Matches the hardware behaviour triggered by an F1 SET_FEATURE with
  /// command byte 0x0A: overwrites the 16-byte region at the current pointer.
  void writeBlock(Iterable<int> data) {
    bankData(currentBank).setAll(currentAddress, data);
  }
}
