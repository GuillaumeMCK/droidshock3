/// Where the bridge lives on the device, with its process file and log.
const kBridgeDir = '/data/local/tmp/ds3_bridge';

/// How often the gadget sends the PS3 an input report: the latest state the
/// client sent, so the client needn't send more often.
const kInputReportInterval = Duration(milliseconds: 8);

/// The first line the bridge writes to stderr when it fails, for the app to
/// spot in its log.
const kBridgeFatalError = '--- Bridge encountered a fatal error ---';

/// How often the bridge checks whether the client process is still alive.
const kPidPollInterval = Duration(seconds: 1);

/// **Client → server**
/// | Opcode          | Value  | Meaning                        |
/// |-----------------|--------|--------------------------------|
/// | [inputReport]   | `0x01` | 48-byte input report           |
/// | [shutdown]      | `0xFF` | Graceful shutdown request      |
///
/// **Server → client**
/// | Opcode         | Value  | Meaning                        |
/// |----------------|--------|--------------------------------|
/// | [outputReport] | `any`  | 48-byte output report          |
enum Op {
  /// DS3 input report sent by the client (bytes 1–48 = HID payload).
  inputReport(0x01),

  /// DS3 output report sent by the server (bytes 1–48 = HID payload).
  outputReport(0x10),

  /// Graceful shutdown request sent by the client (payload ignored).
  shutdown(0xFF);

  const Op(this.byte);

  /// Raw opcode byte on the wire.
  final int byte;

  static final _client = {
    inputReport.byte: Op.inputReport,
    shutdown.byte: Op.shutdown,
  };

  static final _server = {outputReport.byte: Op.outputReport};

  /// Returns the [Op] matching [b], or `null` if unrecognised.
  static Op? parseClientFrame(int b) => _client[b];

  /// Returns the [Op] matching [b], or `null` if unrecognised.
  static Op? parseServerFrame(int b) => _server[b];

  /// Fixed frame length for every message in both directions.
  /// [ op + payload ]
  static const frameLength = 49;
}
