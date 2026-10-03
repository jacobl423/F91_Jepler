# PROJECT_CONTEXT

This file preserves the original user prompt, design goals, and architectural decisions made during the initial planning phase of the `f91_jepler` project. It is intended to provide full context to future AI agents or contributors working on the repository.

---

## Original User Request & Design Goals

**PROJECT CONTEXT — CUSTOM CASIO F-91W SMARTWATCH / KEPLER REDESIGN**

I am designing a custom smartwatch PCB that fits inside a Casio F-91W case. The project is based on / inspired by the open-source drpykachu/F91_Kepler project:

https://github.com/drpykachu/F91_Kepler

The original Kepler uses a TI CC2640R2F, monochrome OLED, Bluetooth LE, CR2016 battery, and custom PCB that fits inside the F-91W. I want to use the Kepler PCB/layout/mechanical dimensions as a starting point, but I am willing to substantially redesign the electronics.

This is NOT intended to remain a faithful Kepler clone. The goal is to make a modern, highly hackable/reprogrammable F-91W smartwatch while retaining the original F-91W case, physical buttons, and general form factor.

**PRIMARY DESIGN GOALS**

1. **THREE-BUTTON INPUT**
The Casio F-91W has three physical buttons. All three should be independently connected to MCU GPIOs and usable by firmware. Firmware should support short press, long press, potentially double press, and software debouncing. Button assignments should remain configurable in firmware.

2. **NEW MCU**
We are replacing the original TI CC2640R2F because its 128 KB flash and 20 KB RAM are restrictive.
Chosen MCU: **Nordic nRF52840 (QFN48 / 6x6 mm)**.
Advantages: ARM Cortex-M4F, 1 MB internal flash, 256 KB RAM, Bluetooth LE, strong open-source ecosystem (Zephyr), OTA/DFU firmware updating.

3. **DISPLAY**
*Initial Goal:* Higher-resolution FULL-COLOR RGB display (e.g., GC9107).
*Final Decision:* We reverted back to retaining the original **0.83" Monochrome OLED (SSD1306, 96x39)**. This ensures perfect mechanical compatibility without case sanding, drastically reduces power consumption, avoids the need for a buck-boost voltage regulator, and saves massive amounts of RAM.

4. **RECHARGEABLE BATTERY**
We want a rechargeable coin-cell solution while preserving approximately the CR2016 physical form factor.
Chosen Battery: **ML2016** rechargeable lithium coin cell (~3.0V nominal).
We are discarding the original Casio metal internal cage and instead using a low-profile SMD battery retainer (e.g., Keystone 3003) soldered directly to the back of the PCB.

5. **TWO-CONTACT CHARGING INTERFACE (The "Floating Button" Architecture)**
We want to use the watch's physical side buttons as a charging input by inserting the watch into a dock that pushes the buttons down. 
Because we discarded the internal metal VCC cage, the stainless steel buttons sit suspended in the resin case and are electrically floating. The PCB edge cutouts will feature **split (interdigitated) pads**. When a button is pushed by a dock (applying 5V to one button and GND to another), the flat inner tip of the metal button bridges the split pads, safely routing power to an internal charging IC while series resistors protect the MCU GPIOs from 5V overvoltage.

6. **OTA / WIRELESS FIRMWARE UPDATES**
Normal firmware development and updates should NOT require opening the watch. We will use Zephyr's SMP Server for OTA DFU. Physical programming/debug access (SWD) will still exist internally as emergency recovery.

7. **DEVELOPMENT / DEBUGGING**
Firmware should be designed to be easy to modify with AI-assisted workflows. We are migrating to the Zephyr RTOS / nRF Connect SDK.

8. **EXTERNAL FLASH**
Retain an OPTIONAL external SPI flash footprint (e.g., MX25R1635F USON-8) for future logging or dual-bank OTA images.

9. **SENSORS**
Added a tiny low-power 3-axis accelerometer (ST LIS2DW12) for step counting, tap gestures, and raise-to-wake functionality.

10. **SOUND**
Retaining the original F-91W piezo/beeper system attached to the case back.

---

## Resolved Pre-Manufacturing Checklist (Hardware Architecture)

- **Mechanicals:** Parsing the original Kepler movement holder STL yields a maximum bounding box of approx 26.18 mm x 25.47 mm x 4.40 mm.
- **PCB Stack:** A 0.8mm or 1.0mm 4-layer board is recommended for the nRF52840 to ensure proper ground planes and RF impedance matching.
- **Button Routing:** Solved via the Split-Pad Design.
    - Button A (Top-Left - Charger Positive): Pad A1 goes to Charger `VIN`. Pad A2 goes to MCU GPIO via 100kΩ series resistor.
    - Button B (Bottom-Left - Charger Negative): Pad B1 goes to `GND`. Pad B2 goes to MCU GPIO.
    - Button C (Right - Standard UI): Wired identically to Button B.
- **Power Architecture:** Solved. Because we are using the SSD1306 OLED, we DO NOT need a buck-boost regulator. Both the nRF52840 and the SSD1306 can operate natively down to lower voltages directly from the ML2016 battery. The only required power circuitry is a tiny 3.1V constant-voltage charging IC (e.g., TPS7A0531P LDO).
- **Firmware Stack:** Zephyr RTOS / nRF Connect SDK.

---
*Future Agents: Use this document to understand the underlying mechanical restrictions of the F-91W case, the exact components selected for the `f91_jepler` redesign, and the unique split-pad charging architecture that allows the case to remain watertight and unmodified.*
