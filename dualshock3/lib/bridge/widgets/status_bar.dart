import '../bridge_cubit.dart';
import '/common/common.dart';

class BridgeStatusBar extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = useBlocState(getIt<BridgeCubit>());
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 100),
      child: switch (state) {
        _ => Text('$state'),
      },
    );
  }
}
