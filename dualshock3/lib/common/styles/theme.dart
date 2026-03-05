import '/common/common.dart';

export 'package:shadcn_ui/shadcn_ui.dart';

const ShadStoneColorScheme _lightTheme = .light();
const ShadStoneColorScheme _darkTheme = .dark();

ShadThemeData themeData(int? hue, bool isDark) {
  final theme = isDark ? _darkTheme : _lightTheme;
  final rawColor = hue ?? theme.primary.toARGB32();
  final primary = Color(rawColor).shiftBrightness();
  final secondary = Color.lerp(theme.secondary, primary, .01);
  final input = (isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFFFFF));
  final background = isDark ? const Color(0xFF000000) : const Color(0xFFF9F9F9);
  final adaptative = input.shiftBrightness(
    darkAmount: isDark ? -.145 : .15,
    lightAmount: isDark ? .15 : -.05,
  );
  final colorScheme = theme.copyWith(
    primary: primary,
    background: background,
    secondary: secondary,
    input: input,
    popover: input,
    popoverForeground: .lerp(theme.popoverForeground, primary, .01),
    card: adaptative,
    cardForeground: .lerp(theme.cardForeground, primary, .01),
    ring: .lerp(theme.ring, primary, .1)!.faint,
    foreground: .lerp(theme.foreground, primary, .01)!.withAlpha(225),
    destructive: const Color(0xFFE00004),
    accent: .lerp(theme.accent, primary, .01),
    accentForeground: .lerp(theme.accentForeground, primary, .01),
    muted: .lerp(theme.muted, primary, .01),
    mutedForeground: theme.mutedForeground.withAlpha(225),
    selection: primary.withAlpha(isDark ? 75 : 40),
    border: isDark ? const Color(0xFF2A2B2F) : const Color(0xFFEAEAEC),
  );
  return ShadThemeData(
    brightness: isDark ? .dark : .light,
    colorScheme: colorScheme,
    buttonSizesTheme: _buttonsSizes,
    textTheme: textTheme(colorScheme),
    popoverTheme: _popoverTheme(colorScheme),
    accordionTheme: const ShadAccordionTheme(padding: .all(4)),
    cardTheme: ShadCardTheme(
      backgroundColor: colorScheme.card,
      border: .all(width: .5),
      radius: const .all(.circular(24)),
      padding: const .all(8),
    ),
    selectTheme: ShadSelectTheme(
      decoration: _selectDecoration(colorScheme),
      padding: const .symmetric(horizontal: 8, vertical: 6),
      anchor: const ShadAnchorAuto(),
      popoverReverseDuration: 50.ms,
    ),
    primaryButtonTheme: ShadButtonTheme(
      backgroundColor: adaptative,
      pressedBackgroundColor: theme.background,
      foregroundColor: colorScheme.foreground,
      hoverForegroundColor: colorScheme.foreground,
      decoration: _buttonsDecoration.merge(
        ShadDecoration(border: .all(color: colorScheme.border, width: .5)),
      ),
    ),
    destructiveButtonTheme: ShadButtonTheme(
      backgroundColor: colorScheme.destructive,
      pressedBackgroundColor: colorScheme.destructive.darker,
      foregroundColor: colorScheme.destructiveForeground,
      hoverForegroundColor: colorScheme.destructiveForeground,
      decoration: _buttonsDecoration,
    ),
    secondaryButtonTheme: ShadButtonTheme(
      backgroundColor: adaptative.withAlpha(80),
      pressedBackgroundColor: adaptative.withAlpha(110),
      foregroundColor: colorScheme.mutedForeground,
    ),
  );
}

const _buttonsSizes = ShadButtonSizesTheme(
  sm: ShadButtonSizeTheme(height: 36, padding: .symmetric(horizontal: 10)),
  regular: ShadButtonSizeTheme(
    height: 36 + 2,
    padding: .symmetric(horizontal: 12),
  ),
  lg: ShadButtonSizeTheme(height: 36 + 4, padding: .symmetric(horizontal: 14)),
);

const _buttonRadius = BorderRadius.all(.circular(10));
const _buttonFocusRadius = BorderRadius.all(.circular(14));
final _buttonsDecoration = ShadDecoration(
  border: .all(radius: _buttonRadius),
  secondaryErrorBorder: .all(radius: _buttonRadius),
  errorBorder: .all(radius: _buttonRadius),
  secondaryBorder: .all(radius: _buttonRadius),
  secondaryFocusedBorder: .all(radius: _buttonFocusRadius),
);

ShadDecoration _selectDecoration(ShadColorScheme colorScheme) => ShadDecoration(
  color: colorScheme.transparent,
  border: ShadBorder.none,
  secondaryErrorBorder: .all(color: colorScheme.destructive),
);

ShadPopoverTheme _popoverTheme(ShadColorScheme colorScheme) {
  return ShadPopoverTheme(
    padding: const .all(2),
    shadows: const [],
    reverseDuration: 100.ms,
    decoration: ShadDecoration(
      color: colorScheme.input.veryFaint,
      border: .all(color: colorScheme.border, radius: const .all(.circular(6))),
    ),
  );
}

extension ThemeUtilsX on BuildContext {
  ShadThemeData get theme => ShadTheme.of(this);

  ShadTextTheme get textTheme => ShadTheme.of(this).textTheme;

  ShadColorScheme get colorScheme => ShadTheme.of(this).colorScheme;

  Brightness get brightness => ShadTheme.of(this).brightness;

  bool get isDark => brightness == .dark;

  bool get isLight => brightness == .light;
}

extension ShadThemeDataX on ShadColorScheme {
  Color get transparent => const Color(0x00000000);

  Color get shadow => const Color(0x05000000);
}
