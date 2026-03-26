part of 'bridge_cubit.dart';

enum BridgeStateEnum { none, closed, setup, error, connected, ready }

final class BridgeState {
  const BridgeState._(this.type);

  final BridgeStateEnum type;

  static const none = BridgeState._(.none);

  static const setup = BridgeState._(.setup);

  static const ready = BridgeState._(.ready);

  factory BridgeState.error(Object error, [StackTrace? stackTrace]) =>
      BridgeError(error);

  factory BridgeState.connected(int port) => BridgeConnected(port);

  factory BridgeState.closed(BridgeState previousState) =>
      BridgeClosed(previousState);

  @override
  bool operator ==(Object other) => switch (other) {
    BridgeState() => type == other.type,
    _ => false,
  };

  @override
  int get hashCode => type.hashCode;
}

final class BridgeError extends BridgeState implements Exception {
  const BridgeError(this.error, [this.stackTrace]) : super._(.error);

  final Object error;
  final StackTrace? stackTrace;
}

final class BridgeConnected extends BridgeState {
  const BridgeConnected(this.port) : super._(.connected);

  final int port;
}

final class BridgeClosed extends BridgeState {
  const BridgeClosed(this.previousState) : super._(.closed);

  final BridgeState previousState;
}
