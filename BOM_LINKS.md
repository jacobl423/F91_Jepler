# f91_jepler - Bill of Materials & Purchasing Links

Below is the list of core components required for the f91_jepler hardware redesign, updated to reflect the new **nRF52840 + LiPo/BQ25100** hardware plan.

### 1. Microcontroller (MCU)
*   **Part:** Nordic Semiconductor **nRF52840-QIAA** 
    *   *(Note: The hardware brief mentions a 6x6mm QFN48, but QIAA is typically a 7x7mm AQFN73 package. Double-check the intended footprint during schematic capture).*
*   **Description:** The "brain" of the watch. ARM Cortex-M4F, Bluetooth Low Energy, 1MB Flash, and 256KB RAM. Replaces the CC2640R2F.
*   **Estimated Price:** $5.00
*   **Buy Link:** [Digi-Key: nRF52840](https://www.digikey.com/en/products/filter/rf-transceiver-ics/650?s=N4IgjCBcpgHAzFUBjKAzAhgGwM4FMAaEAeygG0QAWbAVhAF0CAHFSABwDYSB2AdgE4sAJlRoM2fMUKEQnbL36DhYiVPlKpQA)

### 2. Clocking / Crystals
*   **Part:** 32 MHz High-Frequency Crystal
    *   **Description:** Main MCU clock compatible with Nordic reference design.
*   **Part:** 32.768 kHz Low-Frequency Crystal
    *   **Description:** For RTC / precise timekeeping.

### 3. Display
*   **Part:** 0.83-inch Monochrome OLED Display Module (Blue on Black)
*   **Description:** Fits the original Casio F91W window perfectly. Uses an SSD1306 controller and SPI interface.
*   **Estimated Price:** $3.50
*   **Buy Link:** [BuyDisplay (EastRising) ER-OLED0.83-1](https://www.buydisplay.com/0-83-inch-oled-display-module-spi-ssd1306-controller-blue-on-black-96x39)
*   Other color option: [Black background with white text](https://www.buydisplay.com/96x39-pixel-0-83-inch-small-oled-display-manufacturers-i2c-serial-spi)

### 4. Battery & Power Management
*   **Battery Part:** Small Rechargeable 1-cell 3.7V Li-ion/LiPo Battery
    *   **Description:** Pouch cell to replace the disposable CR2016. Exact model to be selected after measuring available F91W internal space. Prefer protected battery.
*   **Charger IC:** Texas Instruments **BQ25100**
    *   **Description:** Very small (1.6x0.9 mm) single-cell Li-ion/LiPo charger supporting 4.2V termination. Will be programmed for ~10mA charging current. Replaces the previous coin cell LDO setup.
    *   **Estimated Price:** ~$1.50
    *   **Buy Link:** [Digi-Key: BQ25100](https://www.digikey.com/en/products/filter/pmic-battery-chargers/781?s=N4IgjCBcpgHAzFUBjKAzAhgGwM4FMAaEAeygG0QAWbAVhAF0CAHFSABwDYSB2AdgE4sAJlRoM2fMUIgADADYZU2Ttlz9hw3oIkiJUtVpA)

### 5. Optional Accelerometer
*   **Part:** STMicroelectronics **LIS2DW12TR** (or similar small low-power 3-axis accelerometer)
*   **Description:** Ultra-low-power 3-axis accelerometer for step counting, wrist tilt detection (raise-to-wake), and tap gestures.
*   **Estimated Price:** $2.10
*   **Buy Link:** [Digi-Key: LIS2DW12TR](https://www.digikey.com/en/products/detail/stmicroelectronics/LIS2DW12TR/7070104)

### 6. Optional Memory Expansion
*   **Part:** Macronix **MX25R1635F**
*   **Description:** 16-Mbit (2MB) Ultra-low-power SPI Flash memory (USON-8). Initial design will omit external flash, but a footprint can be reserved for future use.
*   **Estimated Price:** $1.20
*   **Buy Link:** [Digi-Key: MX25R1635F](https://www.digikey.com/en/products/detail/macronix/MX25R1635FZUIH0/6007421)

---
### **Total Core Component Cost:** ~$13.30 (excluding LiPo battery)

### **Estimated Additional Costs:**
*   **Passive Components (Resistors, Capacitors, etc.):** ~$1.50 per board
*   **Bare PCB (PCBWay):** ~$5.00 for a batch of 5 (excluding shipping)

*Note: The total cost to build a single complete watch (silicon, display, battery, passives, and one PCB from a batch) will be roughly **$23 - $25**, depending heavily on the physical LiPo battery selected.*
