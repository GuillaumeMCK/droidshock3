part of 'bootstrap_cubit.dart';

sealed class BootstrapState {
  const BootstrapState();

  int get step => switch (this) {
    BootstrapLoading(:final step) => step,
    _ => 0,
  };
}

final class BootstrapInitial extends BootstrapState {
  const BootstrapInitial();
}

final class BootstrapLoading extends BootstrapState {
  const BootstrapLoading({this.currentTask, required this.step});

  final String? currentTask;
  final int step;
}

final class BootstrapLoaded extends BootstrapState {
  const BootstrapLoaded({required this.elapsed});

  final Duration elapsed;
}

final class BootstrapError extends BootstrapState {
  const BootstrapError(this.task, this.err, [this.stackTrace]);

  final String task;
  final Object err;
  final StackTrace? stackTrace;
}
