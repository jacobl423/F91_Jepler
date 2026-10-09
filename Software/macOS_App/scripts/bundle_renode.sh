#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
APP_BUNDLE="$1"
shift
CACHE="$ROOT_DIR/build/renode-cache"
VERSION='1.16.1+20260828git00139efee'
mkdir -p "$CACHE" "$APP_BUNDLE/Contents/Resources/Renode"
MOUNT=''
cleanup() {
    if [[ -n "$MOUNT" ]]; then
        hdiutil detach "$MOUNT" -quiet || true
        rmdir "$MOUNT" || true
    fi
}
trap cleanup EXIT
for ARCH in "$@"; do
    case "$ARCH" in
        arm64) PACKAGE_ARCH=arm64; SHA=c3e301a20499d2cb2ba3a0069315428f2d527700349673a43b944e1cc6491a35 ;;
        x86_64) PACKAGE_ARCH=x64; SHA=7a33b5f598dfbebf02ffa325c46e2e78678a1d0499cbcb0c058f4eb93d24bff3 ;;
        *) echo "Unsupported Renode architecture: $ARCH" >&2; exit 1 ;;
    esac
    DMG="$CACHE/$ARCH.dmg"
    URL="https://builds.renode.io/renode-$VERSION.osx-$PACKAGE_ARCH-portable.dmg"
    if [[ ! -f "$DMG" ]]; then
        curl --fail --location --retry 3 "$URL" -o "$DMG.download"
        mv "$DMG.download" "$DMG"
    fi
    ACTUAL=$(shasum -a 256 "$DMG" | cut -d ' ' -f 1)
    if [[ "$ACTUAL" != "$SHA" ]]; then
        echo "Renode checksum mismatch: $DMG. Remove it and retry." >&2
        exit 1
    fi
    MOUNT=$(mktemp -d)
    hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT" -quiet
    DEST="$APP_BUNDLE/Contents/Resources/Renode/$ARCH"
    ditto "$MOUNT/Renode.app/Contents/MacOS" "$DEST"
    ditto "$MOUNT/Renode.app/Contents/Resources" "$DEST/UpstreamResources"
    lipo "$DEST/renode" -verify_arch "$ARCH"
    test -f "$DEST/libcoreclr.dylib"
    test -f "$DEST/licenses/renode-license"
    # Preserve all upstream runtime resources and third-party notices.
    printf 'Renode %s\nSource: %s\nDMG SHA-256: %s\n' "$VERSION" "$URL" "$SHA" > "$DEST/JEPLER_ORIGIN.txt"
    cleanup
    MOUNT=''
done
