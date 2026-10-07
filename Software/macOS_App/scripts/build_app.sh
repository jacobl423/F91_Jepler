#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Jepler Dev.app"

# Use the full Xcode SDK when available, matching the native glass APIs.
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/ModuleCache}"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE_PATH"

cd "$ROOT_DIR"
# Local launches only need the host architecture; release packaging remains universal.
ARCHITECTURES=(arm64 x86_64)
if [[ "${1:-}" == "--native" ]]; then ARCHITECTURES=("$(uname -m)"); fi
BINARIES=()
for ARCH in "${ARCHITECTURES[@]}"; do
    TRIPLE="$ARCH-apple-macosx13.0"
    swift build --disable-sandbox -c release --triple "$TRIPLE"
    BIN_DIR=$(swift build --disable-sandbox -c release --triple "$TRIPLE" --show-bin-path)
    BINARIES+=("$BIN_DIR/F91JeplerEmulator")
done

echo "Creating App Bundle at: $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

if [[ ${#BINARIES[@]} -eq 1 ]]; then
    cp "${BINARIES[0]}" "$APP_BUNDLE/Contents/MacOS/F91JeplerEmulator"
else
    lipo -create "${BINARIES[@]}" -output "$APP_BUNDLE/Contents/MacOS/F91JeplerEmulator"
fi
chmod +x "$APP_BUNDLE/Contents/MacOS/F91JeplerEmulator"

cp "$ROOT_DIR/F91JeplerEmulator/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp -R "$ROOT_DIR/F91JeplerEmulator/Resources/Embedded" "$APP_BUNDLE/Contents/Resources/"

if [ -f "$ROOT_DIR/F91JeplerEmulator/Resources/AppIcon.icns" ]; then
    cp "$ROOT_DIR/F91JeplerEmulator/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc code sign app bundle for macOS Apple Silicon Gatekeeper
echo "Signing application bundle with ad-hoc signature..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Successfully built and signed standalone macOS App Bundle!"
echo "Location: $APP_BUNDLE"
