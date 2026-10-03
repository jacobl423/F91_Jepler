# f91_jepler

## Project Overview

The **f91_jepler** is a complete redesign and evolution of the classic Casio F91W watch, inspired by the original [F91 Kepler](https://github.com/drpykachu/F91_Kepler) project. This project completely replaces the original internals of the watch, keeping only the original resin case and buttons, while adding an OLED display, a powerful Bluetooth-capable MCU, and a rechargeable battery system.

While the original Kepler proved the mechanical concept, the f91_jepler fundamentally upgrades the processing power and introduces a highly experimental, short-circuit-proof external charging mechanism that requires zero case modifications.

<p align="center">
  <img src="Hardware/images/main.jpg" alt="Main view" width="600"/>
</p>

## Hardware Upgrades & Architecture

We have completely redesigned the core architecture to turn this into a modern, highly hackable smartwatch platform:

- **MCU:** Upgraded from the TI CC2640R2F to the **Nordic nRF52840 (QFN48)**. This provides a massive leap in resources (1MB Flash, 256KB RAM) and allows us to use the Zephyr RTOS ecosystem.
- **Display:** Retained the **0.83" Monochrome OLED (SSD1306, 96x39)**. This ensures a perfect mechanical fit in the F91W case and draws incredibly low power, allowing both the MCU and display to run natively off the discharging battery without needing a bulky buck-boost regulator.
- **Sensors:** Added a tiny 2x2mm ultra-low-power accelerometer (Bosch BMA400 or ST LIS2DW12) for step counting and tap/raise-to-wake gesture detection.
- **Battery:** Upgraded from a disposable CR2016 to a **rechargeable ML2016** (Lithium Manganese Dioxide) coin cell.

### Novel Charging System Explorations
To achieve a rechargeable design without drilling holes in the classic Casio case, the f91_jepler is exploring two primary charging architectures that use the external watch buttons as charging contacts:
* **Option A (The "Floating Button" Architecture):** Discard the original Casio metal internal cage entirely and use an SMD battery retainer. This leaves the watch's external stainless steel buttons electrically floating. The PCB uses split (interdigitated) edge pads that the buttons bridge when pushed, allowing a dock to apply 5V to one button and GND to another safely.
* **Option B (Modified Metal Cage):** Retain the original Casio metal cage, but physically cut it in half and add insulation to one side. This isolates two of the buttons from the battery positive (VCC), allowing them to act as separate charging contacts while retaining the original mechanical spring tension provided by the cage.

## Software Architecture

Moving to the nRF52840 means the original Texas Instruments SimpleLink firmware is being completely replaced. The new firmware will be built on:
- **Zephyr RTOS / nRF Connect SDK:** The modern standard for Nordic BLE development.
- **SMP Server:** Allows for safe, dual-bank Over-The-Air (OTA) Device Firmware Updates (DFU) directly from a smartphone, so the watch never needs to be opened for programming once flashed.

## Current Project Status
- **Mechanicals:** Verified (fits original movement holder constraints).
- **Architecture:** Finalized (MCU, Display, Power, and Button charging solved).
- **Schematic & PCB:** Pending / In Progress.
- **Firmware:** Pending / In Progress.

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