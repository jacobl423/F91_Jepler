# f91_jepler - Bill of Materials & Purchasing Links

Below is the initial list of core components required for the f91_jepler hardware redesign, complete with links to purchase them from major distributors. Estimated prices are for single-unit quantities (USD).

### 1. Microcontroller (MCU)
*   **Part:** Nordic Semiconductor **nRF52840** (QFN48 6x6mm package)
*   **Description:** The "brain" of the watch. Features Bluetooth 5, 1MB Flash, and 256KB RAM.
*   **Estimated Price:** $5.00
*   **Buy Link:** [Digi-Key: nRF52840-QFAA](https://www.digikey.com/en/products/filter/rf-transceiver-ics/650?s=N4IgjCBcpgHAzFUBjKAzAhgGwM4FMAaEAeygG0QAWbAVhAF0CAHFSABwDYSB2AdgE4sAJlRoM2fMUKEQnbL36DhYiVPlKpQA)

### 2. Display
*   **Part:** 0.83-inch Monochrome OLED Display Module (Blue on Black)
*   **Description:** Fits the original Casio F91W window perfectly. Uses an SSD1306 controller and SPI interface.
*   **Estimated Price:** $3.50
*   **Buy Link:** [BuyDisplay (EastRising) ER-OLED0.83-1](https://www.buydisplay.com/0-83-inch-oled-display-module-spi-ssd1306-controller-blue-on-black-96x39)

### 3. Accelerometer
*   **Part:** STMicroelectronics **LIS2DW12TR** 
*   **Description:** Ultra-low-power 3-axis accelerometer for step counting, wrist tilt detection (raise-to-wake), and tap gestures. Swapped from BMA400 for better stock availability and cost.
*   **Estimated Price:** $2.10
*   **Buy Link:** [Digi-Key: LIS2DW12TR](https://www.digikey.com/en/products/detail/stmicroelectronics/LIS2DW12TR/7070104)

### 4. Battery & Power
*   **Battery Part:** **ML2016** Rechargeable Lithium Manganese Dioxide Coin Cell
    *   **Description:** 3.0V nominal, 20mm diameter, 1.6mm thickness. Same physical footprint as original but rechargeable.
    *   **Estimated Price:** $7.50
    *   **Buy Link:** [Esslinger: Maxell ML2016 Rechargeable Watch Battery](https://www.esslinger.com/maxell-ml2016-rechargeable-lithium-coin-cell-battery-with-or-without-tabs/)
*   **Battery Retainer:** Keystone **3003** 
    *   **Description:** Surface-mount 20mm battery clip to hold the ML2016.
    *   **Estimated Price:** $1.00
    *   **Buy Link:** [Digi-Key: Keystone 3003](https://www.digikey.com/en/products/detail/keystone-electronics/3003/2745672)
*   **Charging LDO:** Texas Instruments **TPS7A0531P** 
    *   **Description:** Tiny voltage regulator to step down the 5V USB dock voltage to a strict 3.1V constant voltage for safely charging the ML2016 battery.
    *   **Estimated Price:** $0.50
    *   **Buy Link:** [Digi-Key: TPS7A0531P](https://www.digikey.com/en/products/detail/texas-instruments/TPS7A0531PDBVR/9859239)

### 5. Optional / Memory Expansion
*   **Part:** Macronix **MX25R1635F**
*   **Description:** 16-Mbit (2MB) Ultra-low-power SPI Flash memory (USON-8).
*   **Estimated Price:** $1.20
*   **Buy Link:** [Digi-Key: MX25R1635F](https://www.digikey.com/en/products/detail/macronix/MX25R1635FZUIH0/6007421)

---
### **Total Core Component Cost:** ~$20.80

### **Estimated Additional Costs:**
*   **Passive Components (Resistors, Capacitors, etc.):** ~$1.50 per board
*   **Bare PCB (PCBWay):** ~$5.00 for a batch of 5 (excluding shipping)

*Note: The total cost to build a single complete watch (silicon, display, battery, passives, and one PCB from a batch) will be roughly **$23 - $25**, not accounting for shipping costs from the various distributors.*
