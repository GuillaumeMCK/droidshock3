import 'package:auto_route/auto_route.dart';
import 'package:dualshock3/app/app_router.dart';

import '/gamepads/widgets/selector.dart';
import '/common/common.dart';

@RoutePage()
class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisAlignment: .center,
      spacing: 16,
      children: [
        ShadButton(
          onPressed: () => context.pushBridgeLogView(),
          child: const Text('Open Bridge'),
        ),
        GamepadsSelector(),
      ],
    );
  }
}
