#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MacProtectionStatus"
APP_BUNDLE="$APP_NAME.app"
OUTPUT_DMG="$APP_NAME.dmg"
BACKGROUND_SRC="Resources/dmg_background.png"

if ! command -v create-dmg > /dev/null 2>&1; then
    echo "create-dmg not found. Install it with: brew install create-dmg" >&2
    exit 1
fi

echo "1) Building .app bundle..."
./build_app.sh

echo "2) Generating DMG background (Korean if this Mac is set to Korean, English otherwise)..."
swift scripts/generate_dmg_background.swift "$BACKGROUND_SRC"

echo "3) Building disk image ($OUTPUT_DMG)..."
rm -f "$OUTPUT_DMG"
create-dmg \
    --volname "$APP_NAME" \
    --background "$BACKGROUND_SRC" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 104 \
    --icon "$APP_BUNDLE" 150 210 \
    --hide-extension "$APP_BUNDLE" \
    --app-drop-link 510 210 \
    --no-internet-enable \
    "$OUTPUT_DMG" \
    "$APP_BUNDLE" \
    || true # create-dmg returns non-zero if the Finder-styling AppleScript step fails, even though the DMG is still produced

if [ ! -f "$OUTPUT_DMG" ]; then
    echo "create-dmg failed to produce $OUTPUT_DMG" >&2
    exit 1
fi

echo ""
echo "Done: $OUTPUT_DMG"
echo ""
echo "NOTE: the app inside is unsigned (no Developer ID certificate found on this machine)."
echo "On first launch, right-click the app -> Open, or approve it under"
echo "System Settings -> Privacy & Security -> 'Open Anyway'."
