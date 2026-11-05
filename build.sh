#!/bin/bash
# Builds LiquidClean.app and a disk image to install it, without Xcode or an Apple Developer account.
#
#   ./build.sh            release build → build/LiquidClean.app and build/LiquidClean.dmg
#   ./build.sh debug      debug build (no disk image)
#
# The app is ad-hoc signed unless you pass a signing identity:
#
#   SIGN_IDENTITY="Developer ID Application: …" ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP="build/LiquidClean.app"

# A universal app for Apple silicon and Intel Macs: build each architecture, then join them.
# (Building both in one `swift build --arch … --arch …` needs Xcode; this works with the Command Line Tools.)
BINARIES=()
for ARCH in arm64 x86_64; do
    swift build -c "$CONFIG" --triple "$ARCH-apple-macosx14.0"
    BINARIES+=("$(swift build -c "$CONFIG" --triple "$ARCH-apple-macosx14.0" --show-bin-path)/LiquidClean")
done

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "${BINARIES[@]}" -output "$APP/Contents/MacOS/LiquidClean"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign "${SIGN_IDENTITY:--}" "$APP"
echo "Built $APP (signed with: ${SIGN_IDENTITY:-ad-hoc})"

if [ "$CONFIG" = "release" ]; then
    # A disk image with the app and a link to Applications, the usual way to install a Mac app.
    STAGE="$(mktemp -d)"
    trap 'rm -rf "$STAGE"' EXIT
    cp -R "$APP" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"
    rm -f build/LiquidClean.dmg
    hdiutil create -volname "LiquidClean" -srcfolder "$STAGE" -fs HFS+ -format UDZO -quiet build/LiquidClean.dmg
    echo "Built build/LiquidClean.dmg"
fi
echo "Run it with: open $APP"
