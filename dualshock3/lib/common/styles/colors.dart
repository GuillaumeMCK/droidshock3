import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

extension ColorX on Color {
  Color get alphaSolid => withAlpha(0xFF);

  Color get alphaMuted => withAlpha(0x9F);

  Color get alphaFaint => withAlpha(0x60);

  Color get alphaGhost => withAlpha(0x4D);

  Color get alphaTrace => withAlpha(0x13);

  Color get darker => HSLColor.fromColor(this).withLightness(0.4).toColor();

  Color get lighter => HSLColor.fromColor(this).withLightness(0.7).toColor();

  Color shiftLightness({double darkAmount = .05, double lightAmount = .175}) {
    final hsl = HSLColor.fromColor(this);
    final amount = computeLuminance() > 0.5 ? -lightAmount : darkAmount;
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}

extension ShadColorSchemeX on ShadColorScheme {
  Color get transparent => const Color(0x00000000);

  Color get ds3Bg => custom['ds3Bg']!;

  Color get ds3Border => custom['ds3Border']!;

  Color get ds3Fg => custom['ds3Fg']!;

  Color get ds3Pad => custom['ds3Pad']!;

  Color get shadow => const Color(0x05000000);

  Color get success => Color.lerp(const Color(0xFF17C964), foreground, .1)!;

  Color get warning => Color.lerp(const Color(0xFFFFA500), foreground, .1)!;

  Color get error => Color.lerp(const Color(0xFFFF3B30), foreground, .1)!;

  Color get info => Color.lerp(const Color(0xFF0171FF), foreground, .1)!;
}
