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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: switch (state) {
          BootstrapLoading(:final step, :final currentTask) => Column(
            spacing: 16,
            mainAxisSize: .min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: step / BootstrapCubit.steps,
                ),
                duration: 100.ms,
                curve: Effects.engagingCurve,
                builder: (_, value, _) => ShadProgress(
                  color: colorScheme.primary.shiftBrightness(),
                  minHeight: 3,
                  value: value,
                ),
              ),
              Text('$currentTask', style: textTheme.muted.sm),
            ],
          ),
          BootstrapError(:final task, :final err, :final stackTrace) => Column(
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
                  Text(
                    'Bootstrap failed [$task]',
                    style: textTheme.small.medium,
                  ),
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
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
