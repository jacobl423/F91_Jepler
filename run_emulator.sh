#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$ROOT_DIR/Software/macOS_App/build/F91 Jepler Emulator.app"

if [ ! -d "$APP_PATH" ]; then
    echo "App bundle not found. Building F91 Jepler Emulator..."
    bash "$ROOT_DIR/Software/macOS_App/scripts/build_app.sh"
fi

echo "Launching F91 Jepler Emulator.app..."
open "$APP_PATH"
