#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MacProtectionStatus"
APP_BUNDLE="$APP_NAME.app"
OUTPUT_DMG="$APP_NAME.dmg"
VOLUME_NAME="$APP_NAME"
STAGING_DIR=".dmg_staging"

echo "1) Building .app bundle..."
./build_app.sh

echo "2) Staging DMG contents..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "3) Building disk image ($OUTPUT_DMG)..."
rm -f "$OUTPUT_DMG"
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "$OUTPUT_DMG"

rm -rf "$STAGING_DIR"

echo ""
echo "Done: $OUTPUT_DMG"
echo "Open it, then drag $APP_BUNDLE onto the Applications shortcut."
echo ""
echo "NOTE: the app inside is unsigned (no Developer ID certificate found on this machine)."
echo "On first launch, right-click the app -> Open, or approve it under"
echo "System Settings -> Privacy & Security -> 'Open Anyway'."
