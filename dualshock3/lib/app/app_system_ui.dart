import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '/common/styles/styles.dart';

class AppSystemUI extends StatelessWidget {
  const AppSystemUI({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :brightness) = context.theme;
    final Brightness fgBrightness = brightness == .dark ? .light : .dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: WidgetStateColor.transparent,
        systemNavigationBarColor: WidgetStateColor.transparent,
        systemNavigationBarDividerColor: WidgetStateColor.transparent,
        statusBarBrightness: fgBrightness,
        statusBarIconBrightness: fgBrightness,
        systemNavigationBarIconBrightness: fgBrightness,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
