# F91_Jepler

## Project Overview

The **F91_Jepler** is a complete redesign and evolution of the classic Casio F91W watch, inspired by the original [F91 Kepler](https://github.com/drpykachu/F91_Kepler) project. This project completely replaces the original internals of the watch, keeping only the original resin case and buttons, while adding an OLED display, a powerful Bluetooth-capable MCU, and a rechargeable battery system.

The redesign is in progress. Emulation, tooling and companion software are far along; the nRF52840 board itself is not fabricated, and fit and charging arrangements are not yet verified.

<p align="center">
  <img src="Hardware/images/main.jpg" alt="Main view" width="600"/>
</p>

## Progress at a Glance

| Area | Status |
|---|---|
| **Hardware** | Original Kepler DipTrace PCBs converted to editable KiCad 10 projects; redesign draft board carried in the workbench app; BOMs and clock requirements documented. Nothing fabricated yet. |
| **Firmware** | Zephyr RTOS app boots under MCUboot in Renode: RTC-backed ticking clock, SSD1306 framebuffer over I2C, and the custom Notification and Clock GATT services ported to the Zephyr BLE stack. |
| **Emulation** | One-command firmware build with SHA-256 manifest, signed-image boot verification, browser watch viewer with real emulated framebuffer and GPIO buttons, headless boot check. |
| **Jepler Dev (macOS)** | Full Swift workbench: Renode session harness, UART terminal, watch face, firmware build/verify, automated test runner, UART test-bridge injectors, and a live KiCad suite (auto-reload viewer, 3D raytrace, DRC, Gerber export, diff). |
| **Companion app** | React + Capacitor mobile app (Android/iOS) with BLE scan/connect, GATT clock sync, mock driver and LCD watch face; **327/327 tests passing** (`npm test` in `Software/companion_app`). |

## Hardware Upgrades & Architecture

The original Kepler boards were authored in DipTrace; those files are retained unchanged in [`Hardware/PCB/`](Hardware/PCB) and have been converted into editable KiCad projects in [`Hardware/KiCad/`](Hardware/KiCad) (main board, display connector, debugger connector).

The nRF52840 redesign draft (A0) previously lived under `Hardware/KiCad/drafts/f91_jepler/`; that standalone copy was removed when the original boards were converted, and the same draft PCB now ships inside the workbench app at [`Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.kicad_pcb`](Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.kicad_pcb), where the Jepler Dev PCB tools open it by default. It remains an **unrouted electrical-core and placement draft, not a fabrication release**.

- **MCU:** Nordic nRF52840-QIAA, 7 × 7 mm AQFN73, with 1 MB flash and 256 KB RAM.
- **Display:** BuyDisplay ER-OLED0.83-1, a 0.83″ 96 × 39 monochrome OLED driven over I2C (SSD1306-class, Zephyr CFB framebuffer). Connector and supply details remain provisional.
- **Battery:** A small protected single-cell LiPo secured to the assembly replaces the earlier rechargeable coin-cell plan. Exact cell and fit remain provisional.
- **Power:** The draft includes a 3.0 V regulator (not a charger). Onboard charging, charge/load management and the charging connector still need design work.
- **Timekeeping:** External 32.768 kHz crystal feeding the nRF52840 RTC; see [clock circuit requirements](Hardware/CLOCKING.md).
- **Sensors:** An accelerometer and external flash remain optional; neither is in the draft.

### Bracket and charging contacts

Retain the original bracket as the mechanical reference. Its continuity, spring geometry, insulation and clearance around a new battery have not been measured. The user does not currently have it available, so those aspects remain provisional. The draft does not connect the bracket to a battery or charging net. Earlier split-cage and button-charging ideas in the historical project context are not approved electrical designs.

## Software Architecture

Moving to the nRF52840 means the original Texas Instruments SimpleLink firmware is being completely replaced. The new firmware is built on:
- **Zephyr RTOS / nRF Connect SDK:** The modern standard for Nordic BLE development.
- **MCUboot + SMP Server:** MCUboot is the first-stage bootloader with RSA-2048 signed images, and the SMP server allows safe, dual-bank Over-The-Air (OTA) Device Firmware Updates (DFU) directly from a smartphone, so the watch never needs to be opened for programming once flashed.

See [`Firmware/README.md`](Firmware/README.md) for build commands, the GATT service/characteristic map, and flashing notes.

## Development Tooling

### Jepler Dev — macOS workbench (`Software/macOS_App`)

A Swift app that combines the emulator, firmware pipeline and PCB tooling in one window:

- **Renode session harness:** launches Renode with the signed app image and matching MCUboot ELF, streams the UART console, and renders the live emulated framebuffer in a watch frame (the screen is driven by an in-repo `F91SSD1306.cs` model, not a mock drawing).
- **Firmware build & verify:** builds the Zephyr app plus its matching MCUboot image, signs it, and verifies full-file SHA-256 hashes against the generated `firmware-manifest.json` before loading anything into a session.
- **Automated tests & injectors:** boot-test runner and button-sequence presets that assert on firmware-reported state over the emulator-only UART test bridge, plus Notification/Clock service test panels (service-handler payloads, not real BLE/ATT traffic).
- **KiCad suite:** live auto-reload PCB viewer, 3D raytrace render, DRC via `kicad-cli` with SHA-256-pinned input snapshots and explicit pass / fail / inconclusive confidence, Gerber export, PCB diff and comparison, component inspector, board validation and GPIO pin audit against the compiled devicetree.

Build and launch from the repo root:

```bash
./run_emulator.sh          # builds "Jepler Dev.app" if missing, then opens it
```

### Emulation without the app (`Firmware/renode`)

```bash
bash Firmware/renode/build-display.sh   # west build + sign app & MCUboot, export manifest
bash Firmware/renode/watch-ui.sh        # watch viewer at http://127.0.0.1:8085
bash Firmware/renode/boot-check.sh      # headless MCUboot + app boot verification
```

See [`Firmware/renode/README.md`](Firmware/renode/README.md) for details, key bindings, and known limitations.

### Companion app (`Software/companion_app`)

React + Capacitor app for Android/iOS: scans for the watch by name or Clock Service UUID, connects over BLE, and syncs time / timezone / time mode / DST through the GATT clock characteristics, with a simulated-watch driver and an F-91W-style LCD for development. The suite covers serialization boundaries, the connection state machine, sync fault injection and a 4-tier E2E integration suite.

```bash
cd Software/companion_app
npm test          # Vitest: 327/327 passing
npm run typecheck && npm run build
```

## Current Project Status

- **Mechanicals:** Provisional outline and battery envelope; bracket fit unverified.
- **Schematic & PCB:** Original DipTrace boards converted to editable KiCad projects under [`Hardware/KiCad`](Hardware/KiCad); the nRF52840 redesign remains an unrouted draft (bundled with the macOS app). Original DipTrace files retained.
- **Firmware:** Zephyr, MCUboot and the ported GATT services run in Renode; see [emulation instructions](Firmware/renode/README.md). Signed-image boot and a flipped-byte rejection check pass; OTA swapping/rollback has not been tested. Simulation does not validate the physical board.
- **Software:** Jepler Dev workbench builds and launches via `run_emulator.sh`; companion app tests, typecheck and production build pass.

## Collaboration and Setup
Welcome collaborators! To get started with the repository, follow these steps:

1. **Clone the repository**:
   ```bash
   git clone <repository_url>
   cd f91_jepler
   ```

2. **Set up the Python Environment**:
   This project includes some utility scripts for parsing BOMs and STL files, and the Zephyr/west build uses the same environment. It is recommended to use a virtual environment:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Project Structure**:
   - `Firmware/`: Zephyr firmware source and Renode emulation tooling.
   - `Hardware/`: PCB designs (DipTrace originals and KiCad conversions), schematics, and BOMs.
   - `Software/`: Companion mobile app (`companion_app`), the Jepler Dev macOS workbench (`macOS_App`), and the legacy Android shell (`app`).

4. **Contributing**:
   - Please create a new branch for any feature or bugfix (e.g., `feature/add-new-sensor` or `bugfix/fix-display-glitch`).
   - Open a pull request against the `main` branch when your changes are ready for review.
