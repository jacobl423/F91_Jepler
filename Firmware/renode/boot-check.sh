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
app=${APP_BIN:-$root/build/renode-app/app.signed.bin}
bootloader=${MCUBOOT_ELF:-$root/build/renode-app/mcuboot.elf}
display_model=${DISPLAY_MODEL:-$root/Firmware/renode/F91SSD1306.cs}
board_script=${BOARD_SCRIPT:-$root/Firmware/renode/f91_jepler.resc}
[[ "$app" = /* ]] || app="$root/$app"
[[ "$bootloader" = /* ]] || bootloader="$root/$bootloader"
manifest=$(dirname "$app")/firmware-manifest.json
[[ -f "$app" && -f "$bootloader" && -f "$manifest" ]] || {
    echo 'Missing generated app, matching MCUboot ELF, or firmware manifest; run Firmware/renode/build-display.sh first.' >&2
    exit 2
}
python3 - "$app" "$bootloader" "$manifest" <<'PY'
import hashlib, json, pathlib, sys
app, boot, manifest = map(pathlib.Path, sys.argv[1:])
m = json.loads(manifest.read_text())
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
if sha(app) != m.get('imageSHA256') or sha(boot) != m.get('mcubootSHA256'):
    raise SystemExit('Firmware manifest hash mismatch: app/MCUboot are not the exported matching pair.')
if sha(pathlib.Path(m['elfPath']).resolve() if pathlib.Path(m['elfPath']).is_absolute() else app.parent / m['elfPath']) != m['elfSHA256']:
    raise SystemExit('Firmware debug ELF hash mismatch.')
if sha(pathlib.Path(m.get('configPath', 'zephyr/.config')).resolve() if pathlib.Path(m.get('configPath', 'zephyr/.config')).is_absolute() else app.parent / m.get('configPath', 'zephyr/.config')) != m.get('configSHA256'):
    raise SystemExit('Firmware configuration hash mismatch.')
PY
[[ -f "$board_script" ]] || { echo 'Missing Renode board script.' >&2; exit 2; }
[[ -f "$display_model" ]] || { echo 'Missing display model.' >&2; exit 2; }
app_sha=$(shasum -a 256 "$app" | awk '{print $1}')
boot_sha=$(shasum -a 256 "$bootloader" | awk '{print $1}')
display_sha=$(shasum -a 256 "$display_model" | awk '{print $1}')
source_sha=$(shasum -a 256 "$board_script" | awk '{print $1}')
display_binding_sha=$(shasum -a 256 "$(dirname "$board_script")/F91SSD1306.cs" | awk '{print $1}')
[[ "$display_binding_sha" = "$display_sha" ]] || { echo 'Boot-check display model differs from the model included by the board script.' >&2; exit 2; }
runner_sha=$(shasum -a 256 "$0" | awk '{print $1}')
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
using sysbus
\$mcuboot_bin=@$bootloader
\$app_bin=@$app
\$display_model=@$display_model
include @$board_script
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
   ! grep -Eq 'There was an error executing command|Unhandled exception|Unhandled monitor command' "$out/renode.log" &&
   grep -Fq 'Jumping to the first image slot' "$out/uart.log" &&
   grep -Fq 'F91 Jepler Emulation Environment Booting...' "$out/uart.log" &&
   grep -Fq 'Booting Zephyr OS' "$out/uart.log" &&
   grep -Fq 'Watch screen ready' "$out/uart.log" &&
   grep -Fq 'BLE Advertising started' "$out/uart.log" &&
   grep -Fq '[TEST] READY v1' "$out/uart.log"; then
    python3 - "$out/boot-evidence.json" "$app_sha" "$boot_sha" "$display_sha" "$source_sha" "$runner_sha" <<'PY'
import json, pathlib, sys
path, app, boot, display, board, runner = sys.argv[1:]
pathlib.Path(path).write_text(json.dumps({"appSHA256": app, "mcubootSHA256": boot,
                                         "displayModelSHA256": display, "boardScriptSHA256": board,
                                         "bootCheckSHA256": runner, "status": "PASS"}, indent=2) + "\n")
PY
    echo 'PASS: Matching MCUboot/app pair handed off; Zephyr, display, advertising and UART test bridge milestones observed.'
    echo "Evidence: $out/boot-evidence.json"
else
    echo "FAIL: application boot not confirmed; inspect $out/renode.log and uart.log." >&2
    exit 1
fi
