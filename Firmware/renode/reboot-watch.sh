#!/usr/bin/env bash
# Reboot the Renode machine owned by the running browser viewer.
set -euo pipefail
port="${1:-8085}"
if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    echo 'Usage: bash Firmware/renode/reboot-watch.sh [port]' >&2
    exit 2
fi
curl --fail-with-body --silent --show-error --max-time 10 \
    -X POST -H 'X-Watch-UI: 1' "http://127.0.0.1:${port}/api/reboot"
printf '\n'
