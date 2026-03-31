import 'dart:io';
import 'dart:typed_data';

import 'package:using/using.dart';

import 'logger.dart';
import 'protocol.dart';

typedef FrameHandler = void Function(Op op, Uint8List data);
typedef CloseHandler = void Function();

/// A single connected client session.
///
/// Handles framing over TCP — accumulating bytes into a buffer and
/// dispatching complete [Op.frameLength]-byte frames to [onFrame].
/// Calls [onClose] once when the client disconnects or an error occurs.
final class Session with Releasable, BridgeLogger {
  Session({
    required RawSocket socket,
    required this.onFrame,
    required this.onClose,
  }) : _socket = socket {
    remoteAddress = '${socket.remoteAddress.address}:${socket.remotePort}';
    socket.listen(
      _onEvent,
      onDone: release,
      onError: _onError,
      cancelOnError: false,
    );
  }

  late final String remoteAddress;

  final FrameHandler onFrame;
  final CloseHandler onClose;

  final RawSocket _socket;
  final List<int> _buffer = []; // growable buffer for incoming bytes

  /// Writes [frame] to the client. Returns false if the session is released.
  bool send(Op op, List<int> frame) {
    if (isReleased) return false;
    _socket.write([op.byte, ...frame]);
    return true;
  }

  void _onError(Object error, StackTrace st) {
    log.error('Session $remoteAddress error:', error, st);
    release();
  }

  void _onEvent(RawSocketEvent event) {
    switch (event) {
      case .closed:
        onClose();
      case .read:
        final chunk = _socket.read();
        if (chunk case null || []) return;
        _buffer.addAll(chunk);

        while (_buffer.length >= Op.frameLength) {
          final op = Op.parseClientFrame(_buffer[0]);
          if (op == null) {
            _buffer.removeRange(0, Op.frameLength);
            continue;
          }
          final data = Uint8List.fromList(_buffer.sublist(1, Op.frameLength));
          _buffer.removeRange(0, Op.frameLength);
          onFrame(op, data);
        }
      case .write:
    }
  }

  @override
  void release() {
    if (isReleased) return;
    _buffer.clear();
    super.release();
    onClose();
  }
}
