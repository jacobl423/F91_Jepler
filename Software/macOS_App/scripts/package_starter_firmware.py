#!/usr/bin/env python3
"""Package a verified, relocatable firmware set, preserving build provenance."""
import hashlib
import json
from pathlib import Path
import shutil
import sys


def package(source, destination):
    manifest = json.loads((source / 'firmware-manifest.json').read_text())
    files = [
        ('app.signed.bin', 'imageSHA256', 'app.signed.bin'),
        ('mcuboot.elf', 'mcubootSHA256', 'mcuboot.elf'),
        (manifest['elfPath'], 'elfSHA256', 'zephyr.elf'),
        (manifest.get('configPath', 'zephyr/.config'), 'configSHA256', 'firmware.config'),
    ]
    # Validate everything before writing any output.
    for name, key, _ in files:
        path = source / name
        if hashlib.sha256(path.read_bytes()).hexdigest() != manifest.get(key):
            raise ValueError(f'{name} does not match the firmware manifest; rebuild firmware.')
    destination.mkdir(parents=True, exist_ok=True)
    for name, _, target in files:
        shutil.copy2(source / name, destination / target)
    manifest['elfPath'] = 'zephyr.elf'
    manifest['configPath'] = 'firmware.config'
    (destination / 'firmware-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    package(Path(sys.argv[1]), Path(sys.argv[2]))
