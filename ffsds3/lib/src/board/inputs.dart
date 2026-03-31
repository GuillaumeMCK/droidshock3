/// DualShock 3 button definitions with bit positions and analog byte offsets.
///
/// Each button has:
/// - A bit position in the button bitfield (bytes 1-3 of input report)
/// - An analog byte offset for pressure-sensitive buttons
///
/// ## Input Layout
///
/// **Digital Inputs (bytes 1-3):**
/// - Byte 1 (bits 0-7):  SELECT, L3, R3, START, UP, RIGHT, DOWN, LEFT
/// - Byte 2 (bits 8-15): L2, R2, L1, R1, TRIANGLE, CIRCLE, CROSS, SQUARE
/// - Byte 3 (bit 16):    PS
///
/// **Analog Pressure (bytes 14-25):**
/// Pressure bytes are a fixed layout independent of bit positions:
///   14=Up,    15=Right, 16=Down,     17=Left,
///   18=L2,    19=R2,   20=L1,       21=R1,
///   22=Triangle, 23=Circle, 24=Cross, 25=Square
///
/// ## Example
///
/// ```dart
/// // Check if button has analog support
/// if (DS3Input.cross.hasAnalog) {
///   print('Cross pressure byte: ${DS3Input.cross.analogByte}'); // 24
/// }
///
/// // Get bit position for button
/// final bit = DS3Input.triangle.bit; // 12
///
/// // Check a bitmask using IntBitOps
/// final isPressed = buttonByte.bitFlag(DS3Input.cross.bit);
/// ```
enum DS3Input {
  select,
  l3,
  r3,
  start,
  up,
  right,
  down,
  left,
  l2,
  r2,
  l1,
  r1,
  triangle,
  circle,
  cross,
  square,
  ps,
  leftStickX,
  leftStickY,
  rightStickX,
  rightStickY;

  /// Bit position in the button bitfield (0-16).
  ///
  /// Valid for [select] through [ps] only. Asserts on stick axes.
  int get bit {
    assert(
      index <= ps.index,
      '$name is a stick axis and does not have a bit position.',
    );
    return index;
  }

  /// Fixed analog pressure byte offsets keyed by input.
  ///
  /// Matches the DS3 input report layout confirmed by USB inspection.
  static const Set<DS3Input> _analogByteMap = {
    up,
    right,
    down,
    left,
    l2,
    r2,
    l1,
    r1,
    triangle,
    circle,
    cross,
    square,
  };

  /// Byte offset for analog pressure value in the input report.
  ///
  /// Only valid when [hasAnalog] is true. Asserts otherwise.
  int get analogByte {
    assert(
      hasAnalog,
      '$name does not support analog pressure. '
      'Check hasAnalog before accessing analogByte.',
    );
    return bit + 9;
  }

  /// Whether this input has an analog pressure byte in the report.
  bool get hasAnalog => _analogByteMap.contains(this);

  /// Bit mask for use in the button bitfield (1 << bit).
  int get bitMask => 1 << bit;

  bool get isLeftStick => this == leftStickX || this == leftStickY;

  bool get isRightStick => this == rightStickX || this == rightStickY;
}

/// Joystick position with x and y coordinates (0-255, center = 127).
typedef DS3Joystick = ({num x, num y});
