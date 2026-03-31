/// DualShock 3 input report implementation.
///
/// This report is sent from the controller to the host at 100Hz (every 10ms).
/// It contains button states, analog stick positions, analog button pressures,
/// and motion sensor data (accelerometer and gyroscope).
///
/// ## Report Format (48 bytes, index 0-47)
///
/// | Offset | Size | Description                               |
/// |--------|------|-------------------------------------------|
/// | 0      | 1    | Reserved (0x00)                           |
/// | 1-3    | 3    | Input states (bitfield)                   |
/// | 4      | 1    | PS button (bit 0)                         |
/// | 5-8    | 4    | Analog sticks (L.X, L.Y, R.X, R.Y)        |
/// | 9-13   | 5    | Reserved (0x00)                           |
/// | 14-25  | 12   | Analog button pressures                   |
/// | 26-29  | 4    | Reserved (0x00)                           |
/// | 30     | 1    | Unknown (0x05)                            |
/// | 31-40  | 10   | Reserved (0x00)                           |
/// | 41-46  | 6    | Accelerometer + Gyro (big-endian 10-bit)  |
/// | 47     | 1    | Reserved (0x00)                           |
///
/// Analog pressure layout (offsets 14-25):
///   14=Up, 15=Right, 16=Down, 17=Left,
///   18=L2, 19=R2,   20=L1,   21=R1,
///   22=Triangle, 23=Circle, 24=Cross, 25=Square
///
/// ## Example
///
/// ```dart
/// final report = InputReport();
///
/// // Set button states
/// report.setInput(DS3Input.cross, true);
///
/// // Set analog pressure directly
/// report.setAnalog(DS3Input.l2.analogByte, 200);
///
/// // Set stick positions
/// report.setLeftStick((x: 128, y: 128));
/// report.setRightStick((x: 200, y: 100));
///
/// // Get report bytes for USB transmission
/// final bytes = report.bytes; // Uint8List(48)
/// ```
library;

import 'dart:typed_data';
import 'package:usb_gadget/usb_gadget.dart';

import '../board/board.dart';

/// DualShock 3 Input Report (Sent to Host)
final class InputReport {
  InputReport() : _bytes = Uint8List(48), _buttons = 0 {
    // Initialize sticks to neutral (center = 127)
    _bytes[5] = 127; // Left stick X
    _bytes[6] = 127; // Left stick Y
    _bytes[7] = 127; // Right stick X
    _bytes[8] = 127; // Right stick Y
    _bytes[30] = 5; // Unknown constant

    // Initialize accelerometer/gyro to neutral (big-endian 10-bit center = 511)
    // Offsets 41-46: AccelX(41-42), AccelY(43-44), AccelZ(45-46)
    _bytes
      ..setRange(40, 42, 511.toBytes(2)) // AccelX at _bytes[40-41] data[41-42]
      ..setRange(42, 44, 511.toBytes(2)) // AccelY at _bytes[42-43] data[43-44]
      ..setRange(44, 46, 511.toBytes(2)) // AccelZ at _bytes[44-45] data[45-46]
      ..setRange(46, 48, 511.toBytes(2)); // GyroZ  at _bytes[46-47] data[47-48]
  }

  final Uint8List _bytes;
  int _buttons;

  /// Returns a copy of the raw report bytes for USB transmission.
  Uint8List get bytes => Uint8List.fromList(_bytes);

  /// Replaces all internal bytes with [newBytes].
  ///
  /// Also re-syncs the shadow button bitfield so [pressed] stays accurate.
  void update(List<int> newBytes) {
    assert(newBytes.length == 48, 'Input report must be 48 bytes');
    _bytes.setAll(0, newBytes);
    // Re-sync shadow bitfield from bytes 1-3.
    _buttons = _bytes[1] | (_bytes[2] << 8) | (_bytes[3] << 16);
  }

  /// Sets a button's pressed state and automatically updates its analog
  /// pressure byte when applicable.
  ///
  /// [value] may be a [bool] (digital only) or an [int] 0-255 (sets both
  /// digital state and analog pressure).
  void setInput(DS3Input input, Object value) {
    assert(value is bool || value is int, 'Value must be bool or int');

    // Stick axes are routed to their own bytes; they have no bit position.
    if (input.isLeftStick || input.isRightStick) {
      final raw = switch (value) {
        bool() => value ? 255 : 0,
        int() => value.clamp(0, 255),
        _ => throw ArgumentError('Value must be bool or int'),
      };
      switch (input) {
        case DS3Input.leftStickX:
          _bytes[5] = raw;
        case DS3Input.leftStickY:
          _bytes[6] = raw;
        case DS3Input.rightStickX:
          _bytes[7] = raw;
        case DS3Input.rightStickY:
          _bytes[8] = raw;
        default:
          throw StateError('Unhandled stick axis: ${input.name}');
      }
      return;
    }

    final int analogValue = value is bool ? (value ? 255 : 0) : value as int;
    final bool isPressed = analogValue > 0;
    final int clamped = analogValue.clamp(0, 255);

    // Update the shadow bitfield using IntBitOps.bit().
    _buttons = _buttons.bit(input.bit, isPressed ? 1 : 0);

    // Write the three bitfield bytes back to _bytes using IntByteOps.byte().
    _bytes[1] = _buttons.byte(0);
    _bytes[2] = _buttons.byte(1);
    _bytes[3] = _buttons.byte(2);

    if (input.hasAnalog) {
      _bytes[input.analogByte] = clamped;
    }
  }

  /// Returns `true` if the button at [bit] is currently pressed.
  ///
  /// Valid bit range: 0-16. Use [DS3Input.bit] for named constants.
  bool pressed(int bit) {
    assert(bit >= 0 && bit <= 16, 'Input bit must be in range 0-16');
    return _buttons.bitFlag(bit);
  }

  /// Writes [targetValue] (clamped 0-255) to byte [offset] of the report.
  ///
  /// Prefer [setInput] for normal use; this exists for low-level overrides.
  void setAnalog(int offset, int targetValue) {
    assert(offset >= 0 && offset < 48, 'Offset must be in range 0-47');
    _bytes[offset] = targetValue.clamp(0, 255);
  }

  /// Returns the byte at [offset] (0-255).
  int getAnalog(int offset) {
    assert(offset >= 0 && offset < 48, 'Offset must be in range 0-47');
    return _bytes[offset];
  }

  void setLeftStick(DS3Joystick left) {
    _bytes[5] = left.x.toInt().clamp(0, 255);
    _bytes[6] = left.y.toInt().clamp(0, 255);
  }

  void setRightStick(DS3Joystick right) {
    _bytes[7] = right.x.toInt().clamp(0, 255);
    _bytes[8] = right.y.toInt().clamp(0, 255);
  }

  /// Left analog stick position (0-255 each axis, center = 127).
  DS3Joystick get leftStick => (x: _bytes[5], y: _bytes[6]);

  /// Right analog stick position (0-255 each axis, center = 127).
  DS3Joystick get rightStick => (x: _bytes[7], y: _bytes[8]);

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('InputReport:')
      ..writeln('  Buttons:');

    for (final button in DS3Input.values) {
      if (button.isLeftStick || button.isRightStick) continue;
      if (!pressed(button.bit)) continue;

      buffer.write('    ${button.name}: pressed');
      if (button.hasAnalog) {
        buffer.write(' (pressure: ${getAnalog(button.analogByte)})');
      }
      buffer.writeln();
    }
    buffer
      ..writeln('  Left Stick:  (x: ${leftStick.x}, y: ${leftStick.y})')
      ..writeln('  Right Stick: (x: ${rightStick.x}, y: ${rightStick.y})');
    return buffer.toString();
  }
}
