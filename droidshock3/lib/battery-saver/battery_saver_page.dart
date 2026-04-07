import 'package:auto_route/auto_route.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '/common/common.dart';

@RoutePage()
class BatterySaverPage extends HookWidget {
  const BatterySaverPage({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      ScreenBrightness.instance.setApplicationScreenBrightness(0.0);
      return () {
        ScreenBrightness.instance.resetApplicationScreenBrightness();
      };
    });
    return GestureDetector(
      onDoubleTap: () => context.back(),
      child: ColoredBox(color: Color(0xFF000000), child: SizedBox.expand()),
    );
  }
}
