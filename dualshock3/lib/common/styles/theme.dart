import '/common/common.dart';

export 'package:shadcn_ui/shadcn_ui.dart';

final ShadThemeData lightTheme = _themeData(false);
final ShadThemeData darkTheme = _themeData(true);

ShadThemeData _themeData(bool isDark) {
  final ShadStoneColorScheme theme = isDark ? .dark() : .light();
  final primary = Color(0xFF1C6FE0);
  final secondary = Color.lerp(theme.secondary, primary, .01);
  final input = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFFFFF);
  final background = isDark ? const Color(0xFF000000) : const Color(0xFFF9F9F9);
  final adaptative = input.shiftLightness(
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
    ring: .lerp(theme.ring, primary, .1)!.alphaFaint,
    foreground: .lerp(theme.foreground, primary, .01)!.withAlpha(225),
    destructive: const Color(0xFFE00004),
    destructiveForeground: const Color(0xFFFFDDDD),
    accent: .lerp(theme.accent, primary, .01),
    accentForeground: .lerp(theme.accentForeground, primary, .01),
    muted: .lerp(theme.muted, primary, .01)?.shiftLightness(),
    mutedForeground: theme.mutedForeground.withAlpha(225),
    selection: primary.withAlpha(isDark ? 75 : 40),
    border: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEAEAEA),
  );
  return ShadThemeData(
    brightness: isDark ? .dark : .light,
    colorScheme: colorScheme,
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
      decoration: ShadDecoration(
        color: colorScheme.transparent,
        border: .none,
        secondaryErrorBorder: .all(color: colorScheme.destructive),
      ),
      padding: const .symmetric(horizontal: 8, vertical: 6),
      anchor: const ShadAnchorAuto(),
      popoverReverseDuration: 50.ms,
    ),
    buttonSizesTheme: _buttonsSizes,
    primaryButtonTheme: ShadButtonTheme(
      backgroundColor: primary,
      pressedBackgroundColor: primary.shiftLightness(),
      foregroundColor: Color(0xFFFAFAFA),
      hoverForegroundColor: Color(0xFFFFFFFF),
      decoration: _buttonsDecoration,
    ),
    destructiveButtonTheme: ShadButtonTheme(
      backgroundColor: colorScheme.destructive,
      pressedBackgroundColor: colorScheme.destructive.darker,
      foregroundColor: colorScheme.destructiveForeground,
      hoverForegroundColor: colorScheme.destructiveForeground,
      decoration: _buttonsDecoration,
    ),
    secondaryButtonTheme: ShadButtonTheme(
      backgroundColor: secondary,
      pressedBackgroundColor: theme.background,
      foregroundColor: colorScheme.mutedForeground,
      hoverForegroundColor: colorScheme.foreground,
      decoration: _buttonsDecoration.merge(
        ShadDecoration(border: .all(color: colorScheme.border, width: .5)),
      ),
    ),
    outlineButtonTheme: ShadButtonTheme(
      backgroundColor: colorScheme.card,
      pressedBackgroundColor: colorScheme.card.darker,
      foregroundColor: colorScheme.mutedForeground,
      hoverForegroundColor: colorScheme.foreground,
      decoration: _buttonsDecoration.merge(
        ShadDecoration(border: .all(color: colorScheme.border, width: .5)),
      ),
    ),
    ghostButtonTheme: ShadButtonTheme(
      backgroundColor: colorScheme.transparent,
      pressedBackgroundColor: colorScheme.transparent,
      foregroundColor: colorScheme.mutedForeground,
      hoverForegroundColor: colorScheme.foreground,
    ),
  );
}

const _buttonsSizes = ShadButtonSizesTheme(
  sm: ShadButtonSizeTheme(height: 30, padding: .symmetric(horizontal: 10)),
  regular: ShadButtonSizeTheme(height: 36, padding: .symmetric(horizontal: 12)),
  lg: ShadButtonSizeTheme(height: 40, padding: .symmetric(horizontal: 14)),
);

const _buttonRadius = BorderRadius.all(.circular(50));
const _buttonFocusRadius = BorderRadius.all(.circular(50));
final _buttonsDecoration = ShadDecoration(
  border: .all(radius: _buttonRadius),
  secondaryErrorBorder: .all(radius: _buttonRadius),
  errorBorder: .all(radius: _buttonRadius),
  secondaryBorder: .all(radius: _buttonRadius),
  secondaryFocusedBorder: .all(radius: _buttonFocusRadius),
);

ShadPopoverTheme _popoverTheme(ShadColorScheme colorScheme) {
  return ShadPopoverTheme(
    padding: const .all(2),
    shadows: const [],
    reverseDuration: 100.ms,
    decoration: ShadDecoration(
      color: colorScheme.input.alphaGhost,
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
