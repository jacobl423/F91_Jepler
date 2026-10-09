#!/usr/bin/env python3
"""Sign native runtime files explicitly; .NET directories are not Apple bundles."""
from pathlib import Path
import subprocess
import sys

app = Path(sys.argv[1])
mach_o = {b'\xcf\xfa\xed\xfe', b'\xce\xfa\xed\xfe', b'\xfe\xed\xfa\xcf', b'\xca\xfe\xba\xbe', b'\xca\xfe\xba\xbf'}
for path in app.rglob('*'):
    if not path.is_file() or path.is_symlink():
        continue
    with path.open('rb') as stream:
        magic = stream.read(4)
    if magic in mach_o:
        subprocess.run(['codesign', '--force', '--sign', '-', str(path)], check=True, stdout=subprocess.DEVNULL, stderr=None)
subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
