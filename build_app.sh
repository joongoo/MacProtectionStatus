#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MacProtectionStatus"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

echo "Building release binary..."
swift build -c release

echo "Assembling $APP_BUNDLE ..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Sign with a Developer ID cert if one is installed; otherwise fall back to an
# ad-hoc signature so the bundle isn't left completely unsigned.
SIGN_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
if [ -z "$SIGN_IDENTITY" ]; then
    SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
        | { grep "Developer ID Application" || true; } | head -1 | sed -E 's/.*"(.+)"/\1/')
fi

if [ -n "$SIGN_IDENTITY" ]; then
    echo "Signing with Developer ID: $SIGN_IDENTITY"
    codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
else
    echo "No Developer ID certificate found — signing ad-hoc (local use only)."
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

echo "Done: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
