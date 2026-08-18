#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MacProtectionStatus"
APP_BUNDLE="$APP_NAME.app"
PKG_ID="com.local.macprotectionstatus"
VERSION="1.0"
OUTPUT_PKG="$APP_NAME-Installer.pkg"

echo "1) Building .app bundle..."
./build_app.sh

echo "2) Building installer package ($OUTPUT_PKG)..."
rm -f "$OUTPUT_PKG"
pkgbuild \
    --component "$APP_BUNDLE" \
    --install-location "/Applications" \
    --identifier "$PKG_ID" \
    --version "$VERSION" \
    "$OUTPUT_PKG"

echo ""
echo "Done: $OUTPUT_PKG"
echo "Install with: open \"$OUTPUT_PKG\""
echo ""
echo "NOTE: this package is unsigned (no Developer ID certificate found on this machine)."
echo "On first run, Gatekeeper will block it. To open anyway: right-click the .pkg -> Open,"
echo "or run: System Settings -> Privacy & Security -> 'Open Anyway'."
