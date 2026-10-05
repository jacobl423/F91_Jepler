#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$ROOT_DIR/Software/macOS_App/build/F91 Jepler Emulator.app"

echo "Terminating any previous emulator or Renode background processes..."
pkill -9 -f "F91JeplerEmulator" 2>/dev/null || true
pkill -9 -f "renode" 2>/dev/null || true

if [ ! -d "$APP_PATH" ]; then
    echo "App bundle not found. Building F91 Jepler Emulator..."
    bash "$ROOT_DIR/Software/macOS_App/scripts/build_app.sh"
fi

if ! codesign -v "$APP_PATH" 2>/dev/null; then
    echo "Applying ad-hoc code signature to $APP_PATH..."
    codesign --force --deep --sign - "$APP_PATH"
fi

echo "Launching fresh instance of F91 Jepler Emulator.app..."
open -n "$APP_PATH"
