#!/usr/bin/env python3
"""Export verified image provenance and compiled devicetree bindings."""
import hashlib
import json
import pickle
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[2]
out = root / 'build/renode-app'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def git(*args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()

with (out / 'zephyr/edt.pickle').open('rb') as stream:
    edt = pickle.load(stream)
buttons = json.loads((out / 'buttons.json').read_text())
# nRF pinctrl psels encode function at bits 24..31, port at bit 5,
# and pin at bits 0..4. Read only default state, never low-power states.
i2c = edt.get_node('i2c0')
pins = {}
if i2c:
    for state in i2c.pinctrls:
        if state.name != 'default':
            continue
        for conf in state.conf_nodes:
            for group in conf.children.values():
                for psel in group.props.get('psels').val if 'psels' in group.props else []:
                    function = (psel >> 24) & 0xff
                    if function in (11, 12):  # NRF_FUN_TWIM_SCL / NRF_FUN_TWIM_SDA
                        pins['i2cSCL' if function == 11 else 'i2cSDA'] = f'P{(psel >> 5) & 1}.{psel & 31:02d}'
manifest = dict(
    schemaVersion=1, imageSHA256=digest(out / 'app.signed.bin'),
    sourceRevision=git('rev-parse', 'HEAD'),
    sourceDirty=bool(git('status', '--porcelain', '--untracked-files=normal', '--', 'Firmware')),
    board='nrf52840dk/nrf52840', elfPath='zephyr/zephyr.elf',
    elfSHA256=digest(out / 'zephyr/zephyr.elf'),
    configSHA256=digest(out / 'zephyr/.config'), buttons=buttons,
    framebufferHeight=edt.get_node('ssd1306').props['height'].val,
    visibleHeight=39, **pins)
(out / 'firmware-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('Exported image-bound firmware-manifest.json')
