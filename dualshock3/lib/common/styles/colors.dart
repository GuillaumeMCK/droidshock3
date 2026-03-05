import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

extension ColorX on Color {
  Color get opaque => withAlpha(0xFF);

  Color get faint => withAlpha(0x9F);

  Color get mediumFaint => withAlpha(0x60);

  Color get veryFaint => withAlpha(0x4D);

  Color get extremelyFaint => withAlpha(0x13);

  Color get darker => HSLColor.fromColor(this).withLightness(0.4).toColor();

  Color get lighter => HSLColor.fromColor(this).withLightness(0.7).toColor();

  Color shiftBrightness({double darkAmount = .05, double lightAmount = .175}) {
    final hsl = HSLColor.fromColor(this);
    final amount = computeLuminance() > 0.5 ? -lightAmount : darkAmount;
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}

extension ShadColorSchemeX on ShadColorScheme {
  Color get success => Color.lerp(const Color(0xFF17C964), foreground, .1)!;

  Color get warning => Color.lerp(const Color(0xFFFFA500), foreground, .1)!;

  Color get error => Color.lerp(const Color(0xFFFF3B30), foreground, .1)!;

  Color get info => Color.lerp(const Color(0xFF0171FF), foreground, .1)!;
}

abstract class ThemeColors {
  static const black = 0xFF1A1A1A;

  static const white = 0xFFFAFAFA;

  static const colors = [
    white,
    0xFF008E59, // green
    0xFF0081C3, // blue
    0xFF635DAA, // purple
    0xFFD58000, // orange
    0xFFCC4D6A, // pink
    0xFFDD3D51, // red
    0xFFD94608, // brown/orange
  ];
}
