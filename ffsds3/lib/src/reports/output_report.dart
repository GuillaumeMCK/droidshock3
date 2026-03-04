/// DualShock 3 Output Report Implementation
///
/// Full 48-byte output report sent by the host (PS3) to the controller.
///
/// Offset | 00 | 01 | 02 | 03 | 04 | 05-08 | 09  | 0A-1D        | 1E-2F |
/// -------|----|----|----|----|----|-------|-----|--------------|-------|
/// Byte   | ID | RD | RP | LD | LP |  --   | MSK | LED[1..4]×5 |  --   |
///
/// [00] Report ID (always 0x01)
/// [01] Right Motor Duration  — time units (~10 ms each); 0 = disabled
/// [02] Right Motor Power     — small/weak motor; non-zero = on (effectively binary)
/// [03] Left Motor Duration   — time units (~10 ms each); 0 = disabled
/// [04] Left Motor Power      — large/strong motor; 0x00–0xFF intensity
/// [05-08] Reserved / unknown
/// [09] LED Flag Byte — bits 1-4 select which LEDs are active
///        bit 1 (0x02) = LED 1 (rightmost, player 1)
///        bit 2 (0x04) = LED 2
///        bit 3 (0x08) = LED 3
///        bit 4 (0x10) = LED 4 (leftmost, player 4)
///        other bits   = reserved / unknown (0xFF = all on + extras)
/// [0A-0E] LED 1 blink pattern (5 bytes: see LedPattern)
/// [0F-13] LED 2 blink pattern
/// [14-18] LED 3 blink pattern
/// [19-1D] LED 4 blink pattern
/// [1E-2F] Reserved / padding
///
/// LedPattern (5 bytes per LED, starting at byte 0x0A + led_index*5):
///   +0  time_enabled  — total on-time for this blink cycle (units ~10 ms)
///   +1  time_disabled — total off-time for this blink cycle (units ~10 ms)
///   +2  time_on       — on-time within one blink pulse  (units ~10 ms)
///   +3  time_off      — off-time within one blink pulse (units ~10 ms)
///   +4  repeat_count  — number of blink cycles (0 = repeat forever)
library;

import 'dart:typed_data';
import 'package:usb_gadget/usb_gadget.dart';

/// Per-LED blink pattern extracted from an [OutputReport].
///
/// Each LED has 5 bytes of blink configuration starting at byte 0x0A
/// (for LED 1), with each subsequent LED offset by 5 bytes.
final class LedPattern {
  const LedPattern({
    required this.timeEnabled,
    required this.timeDisabled,
    required this.timeOn,
    required this.timeOff,
    required this.repeatCount,
  });

  /// Total duration the LED is in the "on" phase of the cycle (~10 ms units).
  /// 0 = LED stays off regardless of other fields.
  final int timeEnabled;

  /// Total duration the LED is in the "off" phase of the cycle (~10 ms units).
  final int timeDisabled;

  /// Duration of each individual on-pulse within the blink (~10 ms units).
  /// When equal to [timeEnabled], the LED is solid (no blinking).
  final int timeOn;

  /// Duration of each individual off-gap within the blink (~10 ms units).
  final int timeOff;

  /// Number of blink cycles to perform. 0 = repeat indefinitely.
  final int repeatCount;

  /// Whether this LED pattern results in a solid (non-blinking) light.
  bool get isSolid => timeOn >= timeEnabled && timeOff == 0;

  /// Whether this LED is effectively disabled (time_enabled == 0).
  bool get isOff => timeEnabled == 0;

  @override
  String toString() =>
      'LedPattern('
      'enabled=$timeEnabled, disabled=$timeDisabled, '
      'on=$timeOn, off=$timeOff, repeat=$repeatCount)';
}

/// DualShock 3 Output Report (Parsed from Host)
final class OutputReport with USBGadgetLogger {
  OutputReport({Uint8List? bytes})
    : bytes = bytes ?? Uint8List(48),
      assert(bytes == null || bytes.length == 48, 'Report must be 48 bytes');

  final Uint8List bytes;

  /// Update the internal state with fresh data from the host.
  void update(List<int> newBytes) {
    if (newBytes.length != 48) {
      throw ArgumentError('Output report must be exactly 48 bytes');
    }
    bytes.setAll(0, newBytes);
    log?.info('Output report updated: $this');
  }

  // ---------------------------------------------------------------------------
  // Rumble
  // ---------------------------------------------------------------------------

  /// Right (small/weak) motor duration [0-255], in ~10 ms units.
  /// Motor fires only when both duration > 0 AND power > 0.
  int get rumbleRightDuration => bytes[1];

  /// Right (small/weak) motor power [0-255].
  /// This motor is effectively binary on the DS3 hardware:
  /// any non-zero value enables it at full speed.
  int get rumbleRightPower => bytes[2];

  /// Left (large/strong) motor duration [0-255], in ~10 ms units.
  /// Motor fires only when both duration > 0 AND power > 0.
  int get rumbleLeftDuration => bytes[3];

  /// Left (large/strong) motor power [0-255].
  /// Actual intensity scales with this value on the DS3 hardware.
  int get rumbleLeftPower => bytes[4];

  /// Whether the right (weak) motor is currently active.
  bool get isRightMotorActive =>
      rumbleRightDuration > 0 && rumbleRightPower > 0;

  /// Whether the left (strong) motor is currently active.
  bool get isLeftMotorActive => rumbleLeftDuration > 0 && rumbleLeftPower > 0;

  // ---------------------------------------------------------------------------
  // LED flag mask (byte 9)
  // ---------------------------------------------------------------------------

  /// Raw LED flag byte (byte 9).
  /// Bits 1-4 correspond to LEDs 1-4; other bits are reserved.
  /// Common PS3 values: 0x02=P1, 0x04=P2, 0x08=P3, 0x10=P4, 0xFF=all.
  int get ledFlagByte => bytes[9];

  /// 4-bit LED mask derived from [ledFlagByte] (bits 1-4 shifted right by 1).
  /// Bit 0 = LED1, bit 1 = LED2, bit 2 = LED3, bit 3 = LED4.
  int get ledMask => (ledFlagByte >> 1) & 0x0F;

  /// Active state of each of the four LEDs, indexed 0 (LED1) to 3 (LED4).
  List<bool> get ledStates => [
    ledMask.bitFlag(0),
    ledMask.bitFlag(1),
    ledMask.bitFlag(2),
    ledMask.bitFlag(3),
  ];

  // ---------------------------------------------------------------------------
  // LED blink patterns (bytes 0x0A–0x1D, 5 bytes × 4 LEDs)
  // ---------------------------------------------------------------------------

  /// Returns the [LedPattern] for the given [ledIndex] (0 = LED1 … 3 = LED4).
  LedPattern ledPattern(int ledIndex) {
    assert(ledIndex >= 0 && ledIndex < 4, 'ledIndex must be 0-3');
    final base = 0x0A + ledIndex * 5;
    return LedPattern(
      timeEnabled: bytes[base + 0],
      timeDisabled: bytes[base + 1],
      timeOn: bytes[base + 2],
      timeOff: bytes[base + 3],
      repeatCount: bytes[base + 4],
    );
  }

  /// Blink patterns for all four LEDs (indices 0-3).
  List<LedPattern> get ledPatterns => List.generate(4, ledPattern);

  @override
  String toString() =>
      'OutputReport('
      'Rumble: L=$rumbleLeftPower (dur=$rumbleLeftDuration) '
      'R=$rumbleRightPower (dur=$rumbleRightDuration), '
      'LEDs: ${ledStates.map((on) => on ? '●' : '○').join(' ')}, '
      'Patterns: ${ledPatterns.map((p) => switch ((p.isOff, p.isSolid)) {
        (true, _) => 'off',
        (false, true) => 'solid',
        _ => p.toString(),
      }).join(', ')})';
}
