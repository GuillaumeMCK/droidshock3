import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/common/common.dart';

typedef AppConstraints = BoxConstraints;

@RoutePage()
class AppShellPage extends HookWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useAppLifecycleState();
    useEffect(() {
      SystemChrome.setEnabledSystemUIMode(.immersiveSticky);
      SystemChrome.setPreferredOrientations([.portraitUp]);
      return null;
    }, [state]);

    return LayoutBuilder(
      builder: (context, constraints) => Provider<AppConstraints>.value(
        value: constraints,
        child: FocusScope(
          child: ColoredBox(
            color: context.colorScheme.background,
            child: AutoRouter(clipBehavior: .none),
          ),
        ),
      ),
    );
  }
}
