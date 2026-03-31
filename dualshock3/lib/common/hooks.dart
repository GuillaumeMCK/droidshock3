import 'dart:async';

import 'package:bloc/bloc.dart';

import 'hooks.dart';

export 'package:leancode_hooks/leancode_hooks.dart';

typedef BlocStateCondition<T> = bool Function(T previous, T current);

extension _FunctionExtension<T> on BlocStateCondition<T> {
  BlocStateCondition<T> get not =>
      (previous, current) => !this(previous, current);
}

/// Returns current state of BlocBase class
///
/// By default [useBlocBuilder] will not filter any states, unless specified [when] condition.
/// [when] local filter function, that will filter incoming states from [BlocBase.stream]
S useBlocBuilder<C extends BlocBase, S>(
  BlocBase<S> bloc, {
  BlocStateCondition<S>? when,
}) {
  return useStream(
        bloc.stream.distinct(when?.not),
        initialData: bloc.state,
        preserveState: false,
      ).data
      as S;
}

/// Listens to the [BlocBase] and executes [listener] callback on every state change.
/// [listener] is called only if [when] condition is met.
void useBlocListener<C extends BlocBase, S>({
  required BlocBase<S> bloc,
  required void Function(S state) listener,
  BlocStateCondition<S>? when,
}) {
  useEffect(() {
    final subscription = bloc.stream.distinct(when?.not).listen(listener);
    return subscription.cancel;
  }, [bloc, listener]);
}

/// Executes a callback every [duration] period.
void usePeriodic(Duration duration, void Function()? callback) {
  useEffect(() {
    final p = Timer.periodic(duration, (_) => callback?.call());
    return p.cancel;
  }, [callback]);
}
