import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '/app/app_widget.dart';
import '/bootstrap/bootstrap_cubit.dart';

Future<void> main() {
  debugPaintSizeEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;
  return BootstrapCubit().run(
    () => runApp(const AppWidget(title: "Pocket DS3")),
    WidgetsFlutterBinding.ensureInitialized(),
  );
}
