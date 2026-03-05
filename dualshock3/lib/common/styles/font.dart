import 'package:flutter/widgets.dart';

import 'styles.dart';

ShadTextTheme textTheme(ShadColorScheme colorScheme) => ShadTextTheme.custom(
  h1Large: ShadTextDefaultTheme.h1Large(family: kDefaultFontFamily),
  h1: ShadTextDefaultTheme.h1(family: kDefaultFontFamily),
  h2: ShadTextDefaultTheme.h2(family: kDefaultFontFamily),
  h3: ShadTextDefaultTheme.h3(family: kDefaultFontFamily),
  h4: ShadTextDefaultTheme.h4(family: kDefaultFontFamily),
  p: ShadTextDefaultTheme.p(family: kDefaultFontFamily).copyWith(
    color: colorScheme.foreground,
    fontSize: 14 + 2,
    fontWeight: FontWeight.w500,
    height: 1.2,
  ),
  blockquote: ShadTextDefaultTheme.blockquote(family: kDefaultFontFamily),
  table: ShadTextDefaultTheme.table(family: kDefaultFontFamily),
  list: ShadTextDefaultTheme.list(family: kDefaultFontFamily),
  lead: ShadTextDefaultTheme.lead(family: kDefaultFontFamily).copyWith(
    color: colorScheme.foreground,
    fontSize: 15 + 2,
    fontWeight: FontWeight.w500,
    height: 1.1,
  ),
  large: ShadTextDefaultTheme.large(family: kDefaultFontFamily).copyWith(
    color: colorScheme.popoverForeground,
    fontSize: 18 + 2,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w500,
  ),
  small: ShadTextDefaultTheme.small(family: kDefaultFontFamily).copyWith(
    color: colorScheme.foreground,
    fontSize: 13 + 2,
    fontWeight: FontWeight.w400,
  ),
  muted: ShadTextDefaultTheme.muted(
    family: kDefaultFontFamily,
  ).copyWith(color: colorScheme.mutedForeground),
  custom: {
    'xs': const TextStyle(
      fontSize: 13 + 2,
      height: 1.2,
      fontFamily: kDefaultFontFamily,
      fontWeight: FontWeight.w500,
    ),
    'xxs': const TextStyle(
      fontSize: 12 + 2,
      height: 1,
      fontFamily: kDefaultFontFamily,
      fontWeight: FontWeight.w400,
    ),
  },
  family: kDefaultFontFamily,
);

extension FontX on ShadTextTheme {
  TextStyle get xs => custom['xs']!;

  TextStyle get xxs => custom['xxs']!;

  TextStyle get keyboard => custom['keyboard']!;
}

extension TextStyleX on TextStyle {
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  TextStyle get underline => copyWith(decoration: TextDecoration.underline);

  TextStyle get strike => copyWith(decoration: TextDecoration.lineThrough);

  TextStyle get mono => copyWith(fontFamily: kDefaultFontFamilyMono);

  TextStyle get sm => copyWith(fontSize: 14, height: 1.2);

  TextStyle get xs => copyWith(fontSize: 13, height: 1.2);

  TextStyle get xxs => copyWith(fontSize: 12, height: 1);

  TextStyle get faint => copyWith(color: color?.withAlpha(60));
}
