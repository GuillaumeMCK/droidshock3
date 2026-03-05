import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';

import '/common/common.dart';

typedef AppConstraints = BoxConstraints;

@RoutePage()
class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme) = context.theme;
    return LayoutBuilder(
      builder: (context, constraints) => Provider<AppConstraints>.value(
        value: constraints,
        child: FocusScope(child: SafeArea(child: AutoRouter())),
      ),
    );
  }
}
