#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Jepler Dev.app"
ZIP_PATH="$BUILD_DIR/Jepler_Dev_Universal.zip"
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
codesign --verify --deep --strict "$APP_BUNDLE"
mkdir -p "$STAGING/payload" "$STAGING/check"
ditto "$APP_BUNDLE" "$STAGING/payload/Jepler Dev.app"
cp "$ROOT_DIR/GETTING_STARTED.md" "$STAGING/payload/GETTING_STARTED.md"
# Preserve symbolic links and macOS metadata covered by the code signature.
ditto -c -k --sequesterRsrc "$STAGING/payload" "$STAGING/release.zip"
ditto -x -k "$STAGING/release.zip" "$STAGING/check"
codesign --verify --deep --strict "$STAGING/check/Jepler Dev.app"
mv "$STAGING/release.zip" "$ZIP_PATH"
echo "Archive verified after extraction: $ZIP_PATH"
