import 'dart:typed_data';

import 'eeprom.dart';

export 'eeprom.dart';
export 'inputs.dart';

/// Represents the physical hardware and identity of the gamepad.
abstract class Board {
  /// The hardware/layout revision code (e.g., 0x8A).
  int get revision;

  /// Unique 32-bit device serial number.
  int get serialnumber;

  /// Controller's hardware MAC address (6 bytes).
  ///
  /// Burned in at manufacturing time — typically starts with Sony's OUI
  /// (e.g., 00:1A:2B).
  Uint8List get deviceAddr;

  /// Host's hardware MAC address (6 bytes).
  ///
  /// For Bluetooth operation, the controller stores the host's MAC
  /// address to enable automatic reconnection.
  Uint8List get pairedAddr;

  /// Interface for the onboard non-volatile memory.
  Eeprom get eeprom;
}
