import 'package:auto_route/auto_route.dart';
import '/bootstrap/bootstrap_cubit.dart';
import '/common/common.dart';

@RoutePage()
class BootstrapPage extends HookWidget {
  const BootstrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final state = useBlocState(getIt<BootstrapCubit>());
    return Container(
      alignment: .center,
      color: colorScheme.background,
      child: switch (state) {
        BootstrapLoading() => _LoadingScreen(state),
        BootstrapError() => _ErrorScreen(state),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

final class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen(this.state);

  final BootstrapLoading state;

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final BootstrapLoading(:step, :currentTask) = state;
    return Container(
      alignment: .center,
      margin: .symmetric(horizontal: 24),
      child: Column(
        spacing: 16,
        mainAxisAlignment: .center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: null, end: step / BootstrapCubit.steps),
            duration: 250.ms,
            curve: Curves.easeInOut,
            builder: (_, value, _) => Text(
              'DROIDSHOCK 3',
              style: textTheme.p.extraBold.noHeight
                  .withColor(colorScheme.primary)
                  .withAlpha(value * 255),
            ),
          ),
          Text('$currentTask', style: textTheme.xxs.withAlpha(127)),
        ],
      ),
    );
  }
}

final class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen(this.state);

  final BootstrapError state;

  @override
  Widget build(BuildContext context) {
    final ShadThemeData(:colorScheme, :textTheme) = context.theme;
    final BootstrapError(:task, :err, :stackTrace) = state;
    return Container(
      alignment: .center,
      padding: .symmetric(horizontal: 24),
      child: Column(
        spacing: 16,
        mainAxisSize: .min,
        children: [
          Row(
            mainAxisSize: .min,
            spacing: 8,
            children: [
              Icon(
                LucideIcons.octagonAlert,
                color: colorScheme.error,
                size: 16,
              ),
              Text('Bootstrap failed [$task]', style: textTheme.small.medium),
            ],
          ),
          Text('$err', style: textTheme.muted.xs),
          ShadAccordion<String>(
            children: [
              ShadAccordionItem(
                value: 'stackTrace',
                title: Text('Stack Trace', style: textTheme.small.medium),
                separator: const SizedBox.shrink(),
                child: ConstrainedBox(
                  constraints: .new(maxHeight: 300, maxWidth: 400),
                  child: SingleChildScrollView(
                    child: Text('$stackTrace', style: textTheme.muted.xs),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
