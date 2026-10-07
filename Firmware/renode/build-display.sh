#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
export ZEPHYR_BASE="$root/zephyr"
export ZEPHYR_TOOLCHAIN_VARIANT=cross-compile
export CROSS_COMPILE=${CROSS_COMPILE:-/opt/homebrew/bin/arm-none-eabi-}
export CCACHE_DIR="$root/build/ccache"
# Exclude the manifest root: its nested zephyr/ tree looks like a module after
# relocating the west workspace under F91_Jepler, causing recursive Kconfig.
modules=$(.venv/bin/python - <<'PY'
import pathlib, subprocess, sys
rows = subprocess.check_output([sys.executable, '-m', 'west', 'list', '-f', '{name}|{abspath}'], text=True)
paths = []
for row in rows.splitlines():
    name, path = row.split('|', 1)
    p = pathlib.Path(path)
    if name not in ('manifest', 'zephyr') and ((p/'zephyr/module.yml').exists() or (p/'zephyr/CMakeLists.txt').exists()):
        paths.append(path)
print(';'.join(paths))
PY
)
.venv/bin/python -m west build -b nrf52840dk/nrf52840 -d build/renode-app Firmware/zephyr -- \
    -DZEPHYR_MODULES="$modules" -DEXTRA_CONF_FILE="$root/Firmware/renode/test-bridge.conf" -DEXTRA_DTC_OVERLAY_FILE="$root/Firmware/renode/display.overlay"
.venv/bin/python bootloader/mcuboot/scripts/imgtool.py sign \
    -k bootloader/mcuboot/root-rsa-2048.pem --header-size 0x200 --align 4 \
    --version 1.0.0 --slot-size 0x76000 --max-sectors 256 \
    build/renode-app/zephyr/zephyr.bin build/renode-app/app.signed.bin
# Generate viewer bindings from the same devicetree used by the firmware.
PYTHONPATH="$root/zephyr/scripts/dts/python-devicetree/src" .venv/bin/python - <<'PY'
import json, pickle
from pathlib import Path
edt = pickle.load(open('build/renode-app/zephyr/edt.pickle', 'rb'))
buttons = []
for key, letter, position in [('1','A','top left'),('2','B','bottom left'),('3','C','bottom right')]:
    gpio = edt.get_node('watch-' + letter.lower()).props['gpios'].val[0]
    port = next(label for label in gpio.controller.labels if label in ('gpio0','gpio1'))
    buttons.append(dict(key=key, label=letter, position=position, port=port,
                        pin=gpio.data['pin'], active_low=bool(gpio.data['flags'] & 1)))
Path('build/renode-app/buttons.json').write_text(json.dumps(buttons, indent=2) + '\n')
PY

PYTHONPATH="$root/zephyr/scripts/dts/python-devicetree/src" .venv/bin/python Firmware/renode/export-manifest.py
