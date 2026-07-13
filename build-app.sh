#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
APP="$ROOT/outputs/网速.app"

cd "$ROOT"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
clang -fobjc-arc -O2 \
    -arch arm64 \
    -arch x86_64 \
    -mmacosx-version-min=13.0 \
    -framework AppKit \
    -framework ServiceManagement \
    "$ROOT/Sources/NetSpeedMenu/main.m" \
    -o "$APP/Contents/MacOS/NetSpeedMenu"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"

echo "$APP"
