# F91 Jepler emulator

## Watch face and keyboard controls

From the project root, build the emulation firmware once, then launch the viewer:

```bash
bash Firmware/renode/build-display.sh
bash Firmware/renode/watch-ui.sh
```

Open http://127.0.0.1:8085 in a browser. `Ctrl+C` in the terminal stops the
viewer and its own Renode process. Use `--port 8086` if 8085 is busy. `RENODE`
can specify the executable; otherwise PATH and the standard macOS installation
are checked. Python uses the existing project `.venv`; the viewer itself needs
only Python's standard library. Building uses the local west/Zephyr workspace,
CMake/Ninja and `arm-none-eabi-` (override `CROSS_COMPILE` if needed).

| Key / case button | Position | Logical alias | Current emulation GPIO |
| --- | --- | --- | --- |
| 1 / A | Top left | watch-a | P0.11, active low |
| 2 / B | Bottom left | watch-b | P0.12, active low |
| 3 / C | Bottom right | watch-c | P0.24, active low |

These GPIOs are the current nRF52840 DK button assignments, **not verified custom
PCB connections**. The repository's PCB files describe the older CC2640 board;
the redesign notes specify A/B/C positions but no nRF GPIO numbers. The keys
match A/B/C as requested. Change the aliases/nodes in `display.overlay` when
the PCB pinout is finalized. The build exports `buttons.json` from the actual
compiled devicetree, so the viewer and firmware use the same assignments.

Click/hold the case buttons or hold number keys (including the number pad).
Inputs go through Renode GPIOs into Zephyr. Quick taps are queued so a press
isn't lost between frames. Losing focus, hiding/closing the page, or missing
heartbeats releases all buttons. Use one controlling browser tab at a time.
The firmware console shows press/release events and virtual hold durations.
The demo temporarily displays pressed button letters; the time is a static
firmware demo value, not a functioning clock application.

The watch outline is a browser UI around the **actual emulated framebuffer**,
not a drawing of the expected screen. A project-local `F91SSD1306.cs` model
receives I2C transactions at `twi0` address `0x3c`. It supports the addressing,
orientation, inversion and blanking commands used by Zephyr, plus headless
frame export. Analog timing, brightness and hardware scrolling aren't modeled.
The virtual glass uses A1/C8 as its normal wiring. The 40-row emulation overlay
allows whole eight-row SSD1306 writes; the original 39-row hardware setting
is left in `Firmware/zephyr/app.overlay`.

`build-display.sh` creates `build/renode-app/app.signed.bin` with the existing
MCUboot development key. It leaves `bin/app.signed.bin` and MCUboot unchanged.
All generated configuration, temporary files, frames and logs remain under
`build/`. Renode may access its normal installed SVD download cache.

For a native Renode display window, from the project root:

```bash
/Applications/Renode.app/Contents/MacOS/renode \
  -e '$app_bin=@build/renode-app/app.signed.bin' \
  -e 'include @Firmware/renode/f91_jepler.resc' \
  -e 'showAnalyzer sysbus.twi0.display' \
  -e 'showAnalyzer sysbus.uart0' \
  -e start
```

The browser viewer is the custom watch outline with keyboard controls.

## Headless MCUboot check

```bash
bash Firmware/renode/boot-check.sh
# Check the display build instead of the original binary:
APP_BIN=build/renode-app/app.signed.bin bash Firmware/renode/boot-check.sh
```

This starts a fresh process, attaches UART0 before execution, runs five simulated
seconds, and quits. A 45-second host watchdog bounds a stalled run. Unique log
directories prevent stale UART results. Exit status 0 requires both MCUboot's
jump message and the application startup marker; 1 means boot was not confirmed.
The original image may boot without successfully drawing, so check for
`Watch screen ready` when using the display build.

FICR CODEPAGESIZE at `0x10000010` is 4096, and CODESIZE at `0x10000014` is 256.
MCUboot's current build enables RSA signatures and `CONFIG_BOOT_VALIDATE_SLOT0`.
The signed image boots from `0xc000`; a separate image with a flipped payload
byte was rejected. OTA swapping/rollback has not been tested.
