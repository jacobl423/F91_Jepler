# f91_jepler - Bill of Materials & Purchasing Links

Below is the initial list of core components required for the f91_jepler hardware redesign, complete with links to purchase them from major distributors.

### 1. Microcontroller (MCU)
*   **Part:** Nordic Semiconductor **nRF52840** (QFN48 6x6mm package)
*   **Description:** The "brain" of the watch. Features Bluetooth 5, 1MB Flash, and 256KB RAM.
*   **Buy Link:** [Digi-Key: nRF52840-QFAA](https://www.digikey.com/en/products/filter/rf-transceiver-ics/650?s=N4IgjCBcpgHAzFUBjKAzAhgGwM4FMAaEAeygG0QAWbAVhAF0CAHFSABwDYSB2AdgE4sAJlRoM2fMUKEQnbL36DhYiVPlKpQA) (Ensure you select the QFAA 48-pin QFN version, not the larger aQFN variant).

### 2. Display
*   **Part:** 0.83-inch Monochrome OLED Display Module (Blue on Black)
*   **Description:** Fits the original Casio F91W window perfectly. Uses an SSD1306 controller and SPI interface.
*   **Buy Link:** [BuyDisplay (EastRising) ER-OLED0.83-1](https://www.buydisplay.com/0-83-inch-oled-display-module-spi-ssd1306-controller-blue-on-black-96x39)

### 3. Accelerometer
*   **Part:** Bosch **BMA400** (or ST LIS2DW12)
*   **Description:** Ultra-low-power 3-axis accelerometer for step counting, wrist tilt detection (raise-to-wake), and tap gestures. Comes in a microscopic 12-pin 2x2mm LGA package.
*   **Buy Link (BMA400):** [Digi-Key: BMA400](https://www.digikey.com/en/products/detail/bosch-sensortec/BMA400/9487771)

### 4. Battery & Power
*   **Battery Part:** **ML2016** Rechargeable Lithium Manganese Dioxide Coin Cell
    *   **Description:** 3.0V nominal, 20mm diameter, 1.6mm thickness. Same physical footprint as the original CR2016 but rechargeable.
    *   **Buy Link:** [Digi-Key: Maxell ML2016](https://www.digikey.com/en/products/detail/maxell/ML2016/16606013)
*   **Battery Retainer:** Keystone **3003** (or similar 20mm SMD retainer)
    *   **Description:** A surface-mount battery clip to securely hold the ML2016 without relying on the Casio's original stamped metal cage.
    *   **Buy Link:** [Digi-Key: Keystone 3003](https://www.digikey.com/en/products/detail/keystone-electronics/3003/2745672)
*   **Charging IC:** Texas Instruments **TPS7A0531P** (or similar precision ultra-low IQ LDO)
    *   **Description:** A tiny voltage regulator to step down the 5V USB dock voltage to a strict 3.1V constant voltage for safely charging the ML2016 battery. A current limiting resistor will be placed in series.
    *   **Buy Link:** [Digi-Key: TPS7A0531P](https://www.digikey.com/en/products/detail/texas-instruments/TPS7A0531PDBVR/9859239)

### 5. Optional / Memory Expansion
*   **Part:** Macronix **MX25R1635F**
*   **Description:** 16-Mbit (2MB) Ultra-low-power SPI Flash memory (USON-8 2x3mm package). Useful for storing extensive accelerometer logs, custom fonts, or dual-bank OTA firmware images.
*   **Buy Link:** [Digi-Key: MX25R1635F](https://www.digikey.com/en/products/detail/macronix/MX25R1635FZUIH0/6007421)

---
*Note: This BOM only lists the major active components. Passive components (resistors, debounce capacitors, decoupling caps) will be finalized once the KiCad schematic is completed.*
