import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:root_plus/root_plus.dart';

import '/bridge/bridge_cubit.dart';
import '/app/app_bloc_observer.dart';
import '/common/common.dart';
import '/env.dart';

part 'bootstrap_state.dart';

late final String fTmpDir;
late final String fAppDir;

class BootstrapCubit extends Cubit<BootstrapState> with BootstrapLogger {
  BootstrapCubit()
    : assert(
        getIt.isRegistered<BootstrapCubit>() == false,
        'BootstrapCubit is already registered in getIt. '
        'Use getIt<BootstrapCubit>() to access the instance instead of '
        'creating a new one.',
      ),
      super(const BootstrapInitial());

  static const steps = 5;

  final Stopwatch watcher = Stopwatch()..start();

  Future<void> run(VoidCallback runApp, WidgetsBinding widgetsBinding) async {
    if (state is! BootstrapInitial) {
      return log?.warn('Bootstrap already started');
    }
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    getIt.registerSingleton<BootstrapCubit>(this);

    configureInjection(env);
    configureLogger();

    Bloc.observer = const AppBlocObserver();
    widgetsBinding.platformDispatcher.onError =
        Logger.logPlatformDispatcherError;

    await _initialize('Storage', () async {
      fTmpDir = (await getTemporaryDirectory()).path;
      fAppDir = (await getApplicationDocumentsDirectory()).path;
      log?.debug(
        'Directories:\n'
        '  Temporary: $fTmpDir\n'
        '  Documents: $fAppDir',
      );
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: .new(fAppDir),
      );
    });

    await _initialize('App Behavior', switch (Platform.operatingSystem) {
      'android' => () async {
        await (
          SystemChrome.setEnabledSystemUIMode(.immersiveSticky),
          SystemChrome.setPreferredOrientations([.portraitUp]),
        ).wait;
      },
      final platform => throw UnsupportedError(platform),
    });

    FlutterNativeSplash.remove();
    runApp();

    if (!await _initialize('Root Access', () async {
      final hasRoot = await RootPlus.requestRootAccess();
      if (!hasRoot) throw Exception('Root access denied');
    }, timeout: null)) {
      return watcher.stop();
    }

    final bridgeCubit = getIt<BridgeCubit>();
    await _initialize('Bridge Setup', bridgeCubit.setup);
    if (bridgeCubit.state case BridgeError(:final error, :final stackTrace)) {
      return emit(BootstrapError('Bridge Setup', error, stackTrace));
    }

    await _initialize('Bridge Connection', bridgeCubit.connect);
    if (bridgeCubit.state case BridgeError(:final error, :final stackTrace)) {
      return emit(BootstrapError('Bridge Connection', error, stackTrace));
    }

    log?.info('Bootstrap took [${watcher.elapsedMilliseconds}ms]');
    watcher.stop();
    await Future.delayed(500.ms);
    emit(BootstrapLoaded(elapsed: watcher.elapsed));
  }

  Future<bool> _initialize<T>(
    String task,
    FutureOr<T> Function() initializer, {
    VoidCallback? onError,
    Duration? timeout = const Duration(seconds: 1),
  }) async {
    final stopWatch = Stopwatch()..start();
    emit(BootstrapLoading(currentTask: task, step: state.step + 1));

    try {
      final future = switch (initializer()) {
        final Future<T> future => future,
        final T value => Future.value(value),
      };
      await (timeout != null
          ? future.timeout(
              timeout,
              onTimeout: () => throw TimeoutException('[$task] timed out'),
            )
          : future);
      log?.info('[$task] initialized successfully');
    } catch (err, st) {
      log?.error('[$task] something went wrong', err, st);
      emit(BootstrapError(task, err, st));
      onError?.call();
      return false;
    } finally {
      stopWatch.stop();
      log?.info('[$task] took ${stopWatch.elapsedMilliseconds}ms');
    }
    return true;
  }
}
