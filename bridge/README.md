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
| Server → Client | `outputReport` | `0x10` | DS3 output report — forwarded as it arrives  |

## Usage

Build it for Android with `tool/build_bridge.sh` (see the script), then run it as root:

```bash
./bridge \
  --client-pid   12345 \        # shut down when this PID exits
  --process-path /tmp/ds3/proc  # where to write <pid>:<port>
```

The app only installs and starts it. On startup the bridge, logging each step:

1. Prints a device description (model, Android, kernel, root manager, SELinux,
   configfs/FunctionFS, USB controllers, gadgets, USB properties) for bug reports.
2. Stops a bridge left running by a previous start: SIGTERM, then SIGKILL.
3. Writes usb_gadget's native library, and mounts configfs if Android hasn't.
4. Takes USB from Android: backs up `persist.sys.usb.config`, sets `sys.usb.config` to
   `none`, and waits for `sys.usb.state` to follow.
5. Registers the DualShock 3 USB gadget, binds it to the default UDC, and listens on
   `127.0.0.1` at an ephemeral port.
6. Writes `<pid>:<port>` to the process file so the app can find the port.

## CLI flags

| Flag                    | Default                              | Description                                                                            |
|-------------------------|--------------------------------------|----------------------------------------------------------------------------------------|
| `--process-path <path>` | `/data/local/tmp/ds3_bridge/process` | Path for the PID/port discovery file                                                   |
| `--client-pid <pid>`    | —                                    | Poll `/proc/<pid>` every second; shut down automatically when the client process exits |

## Shutdown

The bridge shuts down cleanly when any of the following occurs:

- The client sends a `shutdown` (`0xFF`) frame.
- The watched PID disappears from `/proc`.
- It receives SIGTERM or SIGINT.

A client disconnecting doesn't shut it down: another can connect.

On shutdown, in order: the watchdog is cancelled, the session is closed, the TCP server
is closed, the USB gadget is removed, USB is given back to Android, and the process file
is deleted. A fatal error releases it the same way before exiting.
