# F91 Jepler Firmware

This is the firmware for the F91 Smart Watch (Jepler). It is designed to run on the **nRF52840** SoC and is built using the **Zephyr RTOS** (replacing the legacy TI CC2640 architecture).

## Features
- **Zephyr RTOS**: A modern, scalable, and open-source real-time operating system.
- **Display Driver**: Uses an SSD1306 OLED display configured via Zephyr's Character Framebuffer (CFB) API over I2C.
- **OTA Updates**: Integrated with **MCUboot** as the first-stage bootloader, supporting Over-The-Air (OTA) firmware updates via SMP (Simple Management Protocol) over Bluetooth.

## Services and Characteristics (Legacy BLE - Porting in Progress)
Currently the following services and characteristics were present on the previous iteration of the FW. They are being ported to Zephyr's BLE stack:

- `FA35A2F0-7989-11EB-9439-0242AC130002` **Notification Service**
  - `FA35A2F1-7989-11EB-9439-0242AC130002` **Notification Bar** (read, write)
  - `FA35A2F2-7989-11EB-9439-0242AC130002` **Incoming Call** (write)
  - `FA35A2F3-7989-11EB-9439-0242AC130002` **Incoming Text** (write)
- `FA35B2F0-7989-11EB-9439-0242AC130002` **Clock Service**
  - `FA35B2F1-7989-11EB-9439-0242AC130002` **Time** (read, write)
  - `FA35B2F2-7989-11EB-9439-0242AC130002` **Time Zone** (read, write)
  - `FA35B2F3-7989-11EB-9439-0242AC130002` **Time Mode** (read, write)
  - `FA35B2F4-7989-11EB-9439-0242AC130002` **DST** (read, write)

## Compiling (Zephyr West)

The project is compiled using the `west` tool, Zephyr's meta-tool.

1. Create a python virtual environment and activate it:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   ```
2. Build the main application:
   ```bash
   west build -p always -b nrf52840dk/nrf52840 Firmware/zephyr -- -DZEPHYR_TOOLCHAIN_VARIANT=cross-compile -DCROSS_COMPILE=/opt/homebrew/bin/arm-none-eabi-
   ```

*Note: The bootloader is customized via `child_image/mcuboot.conf` to adjust the maximum image sectors to `256` to ensure compatibility with our emulation environment.*

## Emulation with Renode

Since we don't always have physical hardware on hand, we use **Renode** to emulate the nRF52840.

To launch the emulator with the bootloader and signed application:
```bash
/Applications/Renode.app/Contents/MacOS/renode --ui -e "\$mcuboot_bin=@bin/mcuboot.elf; \$app_bin=@bin/app.signed.bin; s @Firmware/renode/f91_jepler.resc; showAnalyzer sysbus.uart0; start"
```

## Flashing (Physical Hardware)

Once the physical watch hardware is ready, you can flash the compiled firmware directly using a J-Link or nRF Connect. The OTA setup allows for subsequent updates to be pushed via Bluetooth using the SMP protocol without needing a physical flasher.
