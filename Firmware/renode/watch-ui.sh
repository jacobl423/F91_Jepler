#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
exec "$root/.venv/bin/python" "$root/Firmware/renode/watch-ui/server.py" "$@"
