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
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT
for ARCH in "${ARCHITECTURES[@]}"; do
    TRIPLE="$ARCH-apple-macosx13.0"
    swift build --disable-sandbox -c release --triple "$TRIPLE"
    BIN_DIR=$(swift build --disable-sandbox -c release --triple "$TRIPLE" --show-bin-path)
    # Xcode's SwiftPM backend may reuse one output path across target triples.
    # Preserve each slice before the next build overwrites that path.
    cp "$BIN_DIR/F91JeplerEmulator" "$STAGING_DIR/F91JeplerEmulator-$ARCH"
    lipo "$STAGING_DIR/F91JeplerEmulator-$ARCH" -verify_arch "$ARCH"
    BINARIES+=("$STAGING_DIR/F91JeplerEmulator-$ARCH")
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
for ARCH in "${ARCHITECTURES[@]}"; do
    lipo "$APP_BUNDLE/Contents/MacOS/F91JeplerEmulator" -verify_arch "$ARCH"
done

cp "$ROOT_DIR/F91JeplerEmulator/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
# Only emulator support and UI assets belong in the application.
mkdir -p "$APP_BUNDLE/Contents/Resources/Embedded"
for RESOURCE in F91SSD1306.cs jepler-icon.png; do
    cp "$ROOT_DIR/F91JeplerEmulator/Resources/Embedded/$RESOURCE" "$APP_BUNDLE/Contents/Resources/Embedded/"
done

if [ -f "$ROOT_DIR/F91JeplerEmulator/Resources/AppIcon.icns" ]; then
    cp "$ROOT_DIR/F91JeplerEmulator/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

bash "$ROOT_DIR/scripts/bundle_renode.sh" "$APP_BUNDLE" "${ARCHITECTURES[@]}"

# Ad-hoc sign the app and its embedded runtimes.
echo "Signing application bundle with ad-hoc signature..."
python3 "$ROOT_DIR/scripts/sign_bundle.py" "$APP_BUNDLE"

echo "Successfully built and signed standalone macOS App Bundle!"
echo "Location: $APP_BUNDLE"
