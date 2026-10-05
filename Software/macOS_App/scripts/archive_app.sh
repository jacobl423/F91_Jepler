#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Jepler Dev.app"
ZIP_PATH="$BUILD_DIR/Jepler_Dev_Universal.zip"

echo "Building Universal 2 App Bundle..."
bash "$ROOT_DIR/scripts/build_app.sh"

echo "Creating Distribution Zip Archive..."
rm -f "$ZIP_PATH"
cd "$BUILD_DIR"
zip -r -q "$ZIP_PATH" "Jepler Dev.app"

echo "===================================================="
echo "SUCCESS: Created Universal 2 App Archive!"
echo "Location: $ZIP_PATH"
echo "Architectures included:"
lipo -info "$APP_BUNDLE/Contents/MacOS/F91JeplerEmulator"
echo "Ready to send to team members on Intel or Apple Silicon Macs!"
echo "===================================================="
