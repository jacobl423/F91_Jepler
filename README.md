# F91_Jepler

## Project Overview

The **F91_Jepler** is a complete redesign and evolution of the classic Casio F91W watch, inspired by the original [F91 Kepler](https://github.com/drpykachu/F91_Kepler) project. This project completely replaces the original internals of the watch, keeping only the original resin case and buttons, while adding an OLED display, a powerful Bluetooth-capable MCU, and a rechargeable battery system.

The redesign is in progress. The original Kepler hardware is a mechanical reference; fit and charging arrangements for the new nRF52840 board are not yet verified.

<p align="center">
  <img src="Hardware/images/main.jpg" alt="Main view" width="600"/>
</p>

## Hardware Upgrades & Architecture

The [KiCad A0 draft](Hardware/KiCad/drafts/f91_jepler/README.md) contains the MCU core and provisional component placement. It is not ready for fabrication.

- **MCU:** Nordic nRF52840-QIAA, 7 × 7 mm AQFN73, with 1 MB flash and 256 KB RAM.
- **Display:** Target SSD1306 96 × 39 OLED. Physical connector, supply and SPI/I2C variant remain to be verified; Renode currently uses I2C.
- **Battery:** A small protected single-cell LiPo secured to the assembly replaces the earlier rechargeable coin-cell plan. Exact cell and fit remain provisional.
- **Power:** The draft includes a 3.0 V regulator. Onboard charging, charge/load management and the charging connector still need design work.
- **Timekeeping:** External 32.768 kHz crystal feeding the nRF52840 RTC; see [clock circuit requirements](Hardware/CLOCKING.md).
- **Sensors:** An accelerometer and external flash remain optional; neither is included in A0.

### Bracket and charging contacts

Retain the original bracket as the mechanical reference. Its continuity, spring geometry, insulation and clearance around a new battery have not been measured. The user does not currently have it available, so those aspects remain provisional. The draft does not connect the bracket to a battery or charging net. Earlier split-cage and button-charging ideas in the historical project context are not approved electrical designs.

## Software Architecture

Moving to the nRF52840 means the original Texas Instruments SimpleLink firmware is being completely replaced. The new firmware will be built on:
- **Zephyr RTOS / nRF Connect SDK:** The modern standard for Nordic BLE development.
- **SMP Server:** Allows for safe, dual-bank Over-The-Air (OTA) Device Firmware Updates (DFU) directly from a smartphone, so the watch never needs to be opened for programming once flashed.

## Current Project Status

- **Mechanicals:** Provisional outline and battery envelope; bracket fit unverified.
- **Schematic & PCB:** Editable [KiCad draft](Hardware/KiCad/drafts/f91_jepler/f91_jepler.kicad_pro), with unrouted placement and documented remaining work. Original DipTrace files retained.
- **Firmware:** Zephyr and MCUboot run in Renode; see [emulation instructions](Firmware/renode/README.md). Simulation does not validate the physical board.

## Collaboration and Setup
Welcome collaborators! To get started with the repository, follow these steps:

1. **Clone the repository**:
   ```bash
   git clone <repository_url>
   cd f91_jepler
   ```

2. **Set up the Python Environment**:
   This project includes some utility scripts for parsing BOMs and STL files. It is recommended to use a virtual environment:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Project Structure**:
   - `Firmware/`: Source code for the watch's microcontroller.
   - `Hardware/`: PCB designs, schematics, and BOMs.
   - `Software/`: Initial work on a companion mobile app.

4. **Contributing**:
   - Please create a new branch for any feature or bugfix (e.g., `feature/add-new-sensor` or `bugfix/fix-display-glitch`).
   - Open a pull request against the `master` branch when your changes are ready for review.
