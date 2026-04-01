# droidshock3

An Android Flutter app (requires root) that turns your phone into a Sony DualShock 3
controller. Pair a Bluetooth gamepad to relay its inputs, or use the on-screen controls
directly. Inputs are forwarded as authentic DS3 HID reports over USB via the
[`bridge`](../bridge/README.md) daemon.

```
Bluetooth gamepad  ──┐
On-screen controls ──┤  droidshock3 (Flutter)
                     │  TCP · loopback
                     ▼
               bridge (daemon)
                     │  ffsds3
                     ▼
            Host (PS3 / PC)
```

###### Features

- **On-screen DualShock 3 layout** — buttons, D-pad, dual analogue sticks, triggers.
- **Bluetooth gamepad pass-through** — pairs any controller and relays its inputs with a
  sensible default mapping.
- **Input remapping** — swap any two DS3 inputs; restore defaults at any time.
- **Player LED feedback** — the PS3's output reports are reflected in the on-screen
  player-ID indicator.

###### Ideas

- **Vibration** — blocked upstream; tracked in [#1](https://github.com/GuillaumeMCK/droidshock3/issues/1).
- **Sixaxis** — phone accelerometer forwarded as DS3 motion data ?
- **Persistent remap** — mappings are currently in-memory only and reset when the app restarts.
- **Localization** — translate UI strings to support multiple languages.
- **Bluetooth Protocol** — implement the dualshock3 bluetooth protocol ?
