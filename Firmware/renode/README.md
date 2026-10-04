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

To cold-boot the same Renode machine while keeping the browser open, run
`bash Firmware/renode/reboot-watch.sh` from another terminal. Pass a port as the
first argument if needed. This reloads MCUboot and the signed display firmware;
the live screen and UART update automatically, with the clock starting at midnight.
The viewer owns a separate headless Renode process, so resetting a separately
launched Renode UI machine will not reset this viewer's machine.

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
The demo temporarily displays pressed button letters. On each application boot,
the clock starts at 12:00:00 AM, advances once per simulated second, and wraps
through noon/PM and midnight/AM. It uses Zephyr uptime backed by the nRF RTC,
not the host clock; pausing Renode pauses time. No time/date is retained across
reboots, and phone time synchronization is not implemented.

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

For the Renode monitor/UART UI, from the project root:

```bash
/Applications/Renode.app/Contents/MacOS/renode --ui \
  -e '$app_bin=@build/renode-app/app.signed.bin' \
  -e 'include @Firmware/renode/f91_jepler.resc' \
  -e 'showAnalyzer sysbus.uart0' \
  -e start
```

On this macOS installation, explicitly use `--ui`; omitting it can produce
`Couldn't start UI - falling back to console mode` even while the firmware
continues running. If already at the Renode monitor, enter `quit` before
launching the command above from the shell. Use the display build under
`build/renode-app/`, not the older `bin/app.signed.bin`.

The new Neutralino `--ui` frontend does not currently provide a video/framebuffer
panel. Its panel registry includes Monitor, Renode Logs, UARTs and Sensors:
https://github.com/antmicro/renode-ui/blob/main/frontend/src/lib/utils.ts
`showAnalyzer sysbus.twi0.display` does not make the watch screen appear in that
frontend. The command above opens the monitor and UART only.

Renode's classic GUI video analyzer requires a working classic GUI backend;
this macOS installation falls back to console mode when launched without `--ui`.
Do not interpret `Watch screen ready` on UART as proof that a host display window
opened: it reports successful firmware display initialization.

The browser viewer shows the Renode framebuffer inside a custom watch outline
with keyboard controls. It remains the available display viewer in this setup.

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

## Timebase

The common application overlay explicitly selects the nRF52840 32.768 kHz crystal
source (`&lfclk`, `k32src = "xtal"`). Renode already models its RTC timers at
32768 Hz; no separate crystal peripheral is required. The 50 ppm declaration
is firmware configuration, not injected drift. Temperature, oscillator startup
and crystal tolerances are not simulated. UART reports the displayed time each
second. Use the rebuilt `build/renode-app/app.signed.bin` in Renode.
