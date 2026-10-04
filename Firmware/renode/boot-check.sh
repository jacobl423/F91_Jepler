#!/usr/bin/env bash
# Start a new Renode process; never connect to or reload an existing UI session.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"
renode=${RENODE:-$(command -v renode || true)}
if [[ -z "$renode" && -x /Applications/Renode.app/Contents/MacOS/renode ]]; then
    renode=/Applications/Renode.app/Contents/MacOS/renode
fi
[[ -x "$renode" ]] || { echo 'Set RENODE to the Renode executable.' >&2; exit 2; }
app=${APP_BIN:-$root/bin/app.signed.bin}
[[ "$app" = /* ]] || app="$root/$app"
[[ -f "$app" && -f bin/mcuboot.elf ]] || { echo 'Missing firmware binaries.' >&2; exit 2; }
mkdir -p "$root/build/renode"
out=$(mktemp -d "$root/build/renode/boot.XXXXXX")
echo "Boot logs: $out"
# Keep configuration, history, temporary files and logs in the project.
mkdir -p "$out/tmp"
export TMPDIR="$out/tmp"
cat > "$out/renode.config" <<EOF
[general]
history-path = $out/history

[tlib]
translation-cache-size = 134217728
EOF
cat > "$out/boot.resc" <<EOF
\$mcuboot_bin=@$root/bin/mcuboot.elf
\$app_bin=@$app
include @$root/Firmware/renode/f91_jepler.resc
sysbus.uart0 CreateFileBackend @$out/uart.log true
emulation RunFor "5"
sysbus.cpu PC
quit
EOF
# RunFor starts and then pauses the simulation; do not issue 'start' first.
# The extra quit also exits if a monitor script command fails.
"$renode" --config "$out/renode.config" --disable-gui --console -p \
    "$out/boot.resc" -e quit > "$out/renode.log" 2>&1 &
pid=$!
# Bound host time too, in case Renode hangs before/inside RunFor.
(
    sleep 45
    kill "$pid" 2>/dev/null || exit 0
    sleep 2
    kill -KILL "$pid" 2>/dev/null || true
) &
watchdog=$!
trap 'kill "$pid" "$watchdog" 2>/dev/null || true' EXIT
status=0
wait "$pid" || status=$?
kill "$watchdog" 2>/dev/null || true
wait "$watchdog" 2>/dev/null || true
trap - EXIT
[[ ! -f "$out/uart.log" ]] || cat "$out/uart.log"
if [[ "$status" -eq 0 ]] &&
   ! grep -Eq 'There was an error executing command|Unhandled exception' "$out/renode.log" &&
   grep -Fq 'Jumping to the first image slot' "$out/uart.log" &&
   grep -Fq 'F91 Jepler Emulation Environment Booting...' "$out/uart.log"; then
    echo 'PASS: MCUboot handed control to the F91 Jepler application.'
else
    echo "FAIL: application boot not confirmed; inspect $out/renode.log and uart.log." >&2
    exit 1
fi
