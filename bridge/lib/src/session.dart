import 'dart:io';
import 'dart:typed_data';

import 'package:protocol/protocol.dart';
import 'package:using/using.dart';

import 'logger.dart';

typedef FrameHandler = void Function(Op op, Uint8List payload);

/// The connected client: splits what it sends into [Op.frameLength]-byte
/// frames for [onFrame], and calls [onClose] once when it disconnects.
final class Session with Releasable, BridgeLogger {
  Session(this._socket, {required this.onFrame, required this.onClose})
    : address = '${_socket.remoteAddress.address}:${_socket.remotePort}' {
    // Frames are small and latency-bound: don't let Nagle hold them.
    _socket
      ..setOption(SocketOption.tcpNoDelay, true)
      ..listen(_onEvent, onError: _onError, onDone: release);
  }

  final String address;
  final FrameHandler onFrame;
  final void Function() onClose;

  final RawSocket _socket;

  /// Received bytes not yet dispatched: at most a partial frame between reads.
  final List<int> _pending = [];

  void send(Op op, List<int> payload) {
    if (!isReleased) _socket.write([op.byte, ...payload]);
  }

  void _onEvent(RawSocketEvent event) => switch (event) {
    .read => _onRead(_socket.read()),
    .readClosed || .closed => release(),
    _ => null,
  };

  void _onError(Object error, StackTrace stack) {
    log.error('Session $address failed:', error, stack);
    release();
  }

  /// Dispatches the complete frames received so far. Input reports are whole
  /// states, so of consecutive ones only the last is dispatched.
  void _onRead(Uint8List? bytes) {
    if (bytes == null) return;
    _pending.addAll(bytes);

    int? lastInput;
    int offset = 0;
    while (offset + Op.frameLength <= _pending.length) {
      switch (Op.parseClientFrame(_pending[offset])) {
        case .inputReport:
          lastInput = offset;
        case final Op op:
          if (lastInput != null) _dispatch(.inputReport, lastInput);
          lastInput = null;
          _dispatch(op, offset);
        case null:
          log.warn('Unknown frame op ${_pending[offset]}: skipped');
      }
      offset += Op.frameLength;
    }
    if (lastInput != null) _dispatch(.inputReport, lastInput);
    _pending.removeRange(0, offset);
  }

  /// Hands [onFrame] the payload of the frame at [offset] in [_pending].
  void _dispatch(Op op, int offset) {
    const payloadLength = Op.frameLength - 1;
    onFrame(
      op,
      Uint8List(payloadLength)
        ..setRange(0, payloadLength, _pending, offset + 1),
    );
  }

  @override
  void release() {
    if (isReleased) return;
    super.release();
    _pending.clear();
    _socket.close();
    onClose();
  }
}
