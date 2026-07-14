#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
STAGING="$ROOT/work/dmg-root"
DMG="$ROOT/outputs/网速.dmg"
APP="$ROOT/outputs/网速.app"
RW_DMG="$ROOT/work/网速-rw.dmg"
MOUNT="$ROOT/work/dmg-mount"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT/Resources/Info.plist")
VERSIONED_DMG="$ROOT/outputs/NetSpeedMenu-$VERSION-universal.dmg"

"$ROOT/build-app.sh"

rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/网速.app"
ln -s /Applications "$STAGING/Applications"
cp "$ROOT/Resources/AppIcon.icns" "$STAGING/.VolumeIcon.icns"

rm -f "$DMG" "$RW_DMG"
rm -rf "$MOUNT"
mkdir -p "$MOUNT"

hdiutil create \
    -volname "网速" \
    -srcfolder "$STAGING" \
    -format UDRW \
    -ov \
    "$RW_DMG"

hdiutil attach -readwrite -nobrowse -mountpoint "$MOUNT" "$RW_DMG"
SetFile -a C "$MOUNT"
sync
hdiutil detach "$MOUNT"

hdiutil convert "$RW_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG"

clang -fobjc-arc -O2 \
    -framework AppKit \
    "$ROOT/Tools/set-file-icon.m" \
    -o "$ROOT/work/set-file-icon"
"$ROOT/work/set-file-icon" "$ROOT/Resources/AppIcon.icns" "$DMG"
cp "$DMG" "$VERSIONED_DMG"

echo "$DMG"
echo "$VERSIONED_DMG"
