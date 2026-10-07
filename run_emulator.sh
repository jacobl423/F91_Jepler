#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$ROOT_DIR/Software/macOS_App/build/Jepler Dev.app"

echo "Launching Jepler Dev without interrupting other Renode sessions..."

# SwiftPM performs an incremental build so an existing bundle cannot mask edits.
bash "$ROOT_DIR/Software/macOS_App/scripts/build_app.sh" --native

if ! codesign -v "$APP_PATH" 2>/dev/null; then
    echo "Applying ad-hoc code signature to $APP_PATH..."
    codesign --force --deep --sign - "$APP_PATH"
fi

echo "Launching fresh instance of Jepler Dev.app..."
open -n "$APP_PATH"
