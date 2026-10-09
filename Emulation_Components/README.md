# External emulation components

In Jepler Dev → Easy Setup, select these three files from this folder:

| Component | File |
| --- | --- |
| KiCad PCB layout | `PCBs/f91_main_board_nf.kicad_pcb` |
| Application firmware | `Firmwares/app.signed.bin` |
| MCUboot bootloader | `Bootloaders/mcuboot.elf` |

Then click **Start Renode**. Leave the optional custom Renode script unset; the app generates the script for these files.

Keep `firmware-manifest.json`, `firmware.config`, and `zephyr.elf` in `Firmwares` beside the application image. They preserve matching-build verification and debugging information; you do not need to select them separately.

These are copies of the PCB from `Hardware/KiCad/f91_main_board_nf` and the verified firmware build from `build/renode-app`, previously used for the external-component boot and notification tests. The manifest retains that build's source revision and hashes; this is not a new firmware build. Files remain external to the app.
