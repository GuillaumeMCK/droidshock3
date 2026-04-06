import 'dart:math';

/// Converts normalized sensor and input values to DS3 wire format.
extension Ds3Conversion on double {
  /// Accelerometer m/s² → DS3 10-bit unsigned (center = 511).
  /// DS3 range: ±2g, sensitivity: 256 LSB/g
  int get toDs3Accel {
    const lsbPerG = 256.0;
    const gravity = 9.80665;
    return (this / gravity * lsbPerG + 511).round().clamp(0, 1023);
  }

  /// Gyroscope rad/s → DS3 10-bit unsigned (center = 511).
  /// DS3 sensitivity: 14.31 LSB/dps
  int get toDs3Gyro {
    const lsbPerDps = 14.31;
    const radToDeg = 180.0 / pi;
    return (this * radToDeg * lsbPerDps + 511).round().clamp(0, 1023);
  }

  /// Analog pressure [0.0–1.0] → DS3 byte (0–255).
  int get toDs3Pressure => (this * 255).round().clamp(0, 255);

  /// Stick axis [-1.0–1.0] → DS3 byte (0–255, center = 127).
  int get toDs3Stick => ((this + 1) / 2 * 255).round().clamp(0, 255);
}
