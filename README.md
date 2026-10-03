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

### The "Floating Button" Charging System
To achieve a rechargeable design without drilling holes in the classic Casio case, the f91_jepler introduces a novel charging architecture:
1. The original Casio internal stamped-metal cage (which tied all buttons to battery positive) has been discarded. 
2. A low-profile SMD battery retainer holds the ML2016, leaving the watch's external stainless steel buttons electrically floating.
3. The PCB features split (interdigitated) edge pads. When a watch button is pressed, its flat inner tip bridges the split pads together, acting as a switch.
4. **Charging:** When placed in a custom dock, the dock pushes the Left-Top button (applying 5V) and the Left-Bottom button (applying Ground). The split pads route this directly to an onboard 3.1V constant-voltage charging IC, safely charging the ML2016 while utilizing series resistors to protect the MCU GPIOs from 5V overvoltage.

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