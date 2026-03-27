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

  @override
  Widget buildOverscrollIndicator(context, child, details) => child;
}
