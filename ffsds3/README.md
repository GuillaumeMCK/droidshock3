# ffsds3

A Dart library for emulating a Sony DualShock 3 controller over USB — make sure to check 
out [`usb_gadget`](https://pub.dev/packages/usb_gadget) before getting started.

> [!NOTE]
> A capture of real DualShock 3 USB traffic is available at [`capture.pcapng`](capture.pcapng) for 
> reference, recorded using [usb-proxy](https://github.com/AristoChen/usb-proxy).

```dart
final (gadget, controller) = createDualshock3();

try {
  final reg = await gadget.register()..bind(defaultUDC);
  await reg.udc?.awaitState(.configured);

  controller.input.setInput(DS3Input.cross, true);
  controller.input.setLeftStick((x: 200, y: 60));

  await ProcessSignal.sigint.watch().first;
} finally {
  await gadget.remove();
}
```

## Inputs

Pass a `bool` for a digital press, or an `int` (0–255) to set both the digital bit and
the analog pressure byte at once.

```dart
controller.input.setInput(DS3Input.cross, true); // digital only
controller.input.setInput(DS3Input.l2, 180);     // analog + digital

controller.input.setLeftStick((x: 200, y: 60));   // 0–255, center = 127
controller.input.setRightStick((x: 127, y: 200));
```

Not all buttons support analog pressure — check `DS3Input.hasAnalog` before reading the
pressure byte.

## Output reports

The PS3 sends output reports to drive the rumble motors and player LEDs.
`OutputReport` is updated automatically from the USB endpoint.

```dart
// Rumble
controller.output.isLeftMotorActive // -> bool
controller.output.rumbleLeftPower   // -> 0–255

// LEDs — index 0 = LED1 (P1) … index 3 = LED4 (P4)
controller.output.ledStates       // -> [true, false, false, false]
controller.output.ledPattern(0)   // -> LedPattern(solid / blinking / off)
```

## EEPROM

The emulated EEPROM ships pre-loaded with factory calibration data. Direct access is
available for testing or advanced customisation.

```dart
// Read a region
final stickCal = controller.eeprom.read(bank: 0, 0x20, 16);

// Patch a single byte
controller.eeprom.writeByte(bank: 0, 0x01, value: 0x03); // Sixaxis type

// F1 pointer operations (mirror hardware behaviour)
controller.eeprom.setPointer(1, 0x90);
final block = controller.eeprom.readBlock(); // 16-byte aligned block
```

## Device identifiers

`createDualshock3()` accepts optional overrides for the MAC addresses and serial number
that are normally burned in at manufacturing time.

```dart
final (gadget, controller) = createDualshock3(
  deviceAddr: [0x00, 0x1A, 0x2B, 0xCC, 0xDD, 0xEE],
  pairedAddr: [0xAA, 0xBB, 0xCC, 0x11, 0x22, 0x33],
  serialnumber: 0xDEADBEEF,
);
```

> [!WARNING]
> `deviceAddr` must use a Sony-registered OUI (first 3 bytes). The PS3 validates the
> Sony vendor ID during enumeration and will reject controllers with an unrecognized
> manufacturer prefix. Use a value sourced from real hardware — for example
> `[0x9E, 0xE8, 0x28, ...]` from a genuine DualShock 3. `serialnumber` is a 32-bit 
> value with no additional constraints.

## CLI

An interactive command-line app is included for quick hardware testing. It registers the
gadget, then toggles inputs based on typed commands — each press flips the button's
current state, and the full input report is printed after every change.

Run it with:

```
sudo dart run bin/ffsds3.dart
```

| Command            | Button                           |
|--------------------|----------------------------------|
| `ps`               | PS / Home                        |
| `cross`, `x`       | Cross                            |
| `circle`, `c`      | Circle                           |
| `square`, `s`      | Square                           |
| `triangle`, `t`    | Triangle                         |
| `start`            | Start                            |
| `select`           | Select                           |
| `up`, `u`          | D-pad Up                         |
| `down`, `d`        | D-pad Down                       |
| `left`, `l`        | D-pad Left                       |
| `right`, `r`       | D-pad Right                      |
| `l1` / `l2` / `l3` | Left shoulder / trigger / stick  |
| `r1` / `r2` / `r3` | Right shoulder / trigger / stick |
| `stk`              | Randomise both analogue sticks   |

Press **Ctrl-C** to detach the gadget and exit.

## Credits & References

- https://eleccelerator.com/wiki/index.php?title=DualShock_3
- https://github.com/lewy20041/DS3_Input_And_Report_Inspector
- https://www.psdevwiki.com/ps3/DualShock_3
- https://github.com/OpenStickCommunity/GP2040-CE