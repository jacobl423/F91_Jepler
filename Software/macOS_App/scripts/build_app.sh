#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Jepler Dev.app"

PLUGIN_DIR="/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins"

echo "Building Swift Universal 2 release binary (arm64 + x86_64 for Intel & Apple Silicon)..."
cd "$ROOT_DIR"

swift build -c release --triple arm64-apple-macosx13.0
ARM_BIN=$(find "$ROOT_DIR/.build" -type f -name "F91JeplerEmulator" | grep -v "\.dSYM" | head -n 1)
cp "$ARM_BIN" "/tmp/F91JeplerEmulator_arm64"

swift package clean
swift build -c release --triple x86_64-apple-macosx13.0
X86_BIN=$(find "$ROOT_DIR/.build" -type f -name "F91JeplerEmulator" | grep -v "\.dSYM" | head -n 1)
cp "$X86_BIN" "/tmp/F91JeplerEmulator_x86_64"

echo "Creating App Bundle at: $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

lipo -create "/tmp/F91JeplerEmulator_arm64" "/tmp/F91JeplerEmulator_x86_64" -output "$APP_BUNDLE/Contents/MacOS/F91JeplerEmulator"
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
