import 'package:flutter/widgets.dart';

class NoScrollBehavior extends ScrollBehavior {
  // @override
  // Widget buildScrollbar(
  //   BuildContext context,
  //   Widget child,
  //   ScrollableDetails details,
  // ) {
  //   return child;
  // }

  Widget buildOverscrollIndicator(context, child, details) => child;
}
