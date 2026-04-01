# bridge

A single-client TCP server that runs on-device, sitting between the `droidshock3` Flutter
app and the [`ffsds3`](../ffsds3/README.md) USB gadget. The bridge owns the full gadget
lifecycle — registration, UDC binding, HID report streaming, and teardown.

```
Flutter app (droidshock3)
        │  TCP · loopback
        ▼
   Ds3Bridge (bridge)
        │  FunctionFS / USB Gadget
        ▼
  Linux USB stack
        │  USB HID
        ▼
   Host (PS3 / PC)
```

## Protocol

Every message in both directions is a fixed **49-byte frame**: 1 opcode byte followed by
48 bytes of HID payload. Frames are accumulated in a growable buffer and dispatched only
when a complete frame is available, handling partial TCP reads correctly.

| Direction       | Opcode         | Value  | Meaning                                      |
|-----------------|----------------|--------|----------------------------------------------|
| Client → Server | `inputReport`  | `0x01` | DS3 input report — forwarded to the USB host |
| Client → Server | `shutdown`     | `0xFF` | Graceful shutdown (payload ignored)          |
| Server → Client | `outputReport` | `0x10` | DS3 output report — pushed every 10 ms       |

## Usage

Compile and run with root privileges:

```bash
dart compile exe bin/bridge.dart -o bridge
sudo ./bridge \
  --client-pid     12345         \   # shut down when this PID exits
  --process-path   /tmp/ds3/proc \   # where to write <pid>:<port>
  --usb-config-bak adb               # sys.usb.config value to restore on exit
```

On startup the bridge:

1. Extracts the bundled `libaio.so` to `/data/local/tmp/ds3_bridge/libaio.so` if not
   already present.
2. Registers the DualShock 3 USB gadget and binds it to the default UDC.
3. Binds a TCP server on `0.0.0.0` at an ephemeral loopback port.
4. Writes `<pid>:<port>` to the process file so the Flutter client can discover the port.
5. Deletes the process file on clean shutdown.

## CLI flags

| Flag                       | Default                              | Description                                                                              |
|----------------------------|--------------------------------------|------------------------------------------------------------------------------------------|
| `--process-path <path>`    | `/data/local/tmp/ds3_bridge/process` | Path for the PID/port discovery file                                                     |
| `--client-pid <pid>`       | —                                    | Poll `/proc/<pid>` every second; shut down automatically when the client process exits   |
| `--usb-config-bak <value>` | —                                    | `sys.usb.config` value to restore via `setprop` on shutdown, handing USB back to Android |

## Shutdown

The bridge shuts down cleanly when any of the following occurs:

- The client sends a `shutdown` (`0xFF`) frame.
- The watched PID disappears from `/proc`.
- The TCP connection closes.

On shutdown, in order: the output timer and watchdog are cancelled, the session is
released, the TCP server is closed, the USB gadget is removed, and the system USB config
is restored if `--usb-config-bak` was provided.