#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
APP="$ROOT/outputs/网速.app"
PACKAGE="$ROOT/outputs/网速安装器.pkg"
COMPONENT_PACKAGE="$ROOT/work/NetSpeedMenu-component.pkg"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT/Resources/Info.plist")
VERSIONED_PACKAGE="$ROOT/outputs/NetSpeedMenu-$VERSION-universal.pkg"

"$ROOT/build-app.sh"

mkdir -p "$ROOT/work"
rm -f "$COMPONENT_PACKAGE" "$PACKAGE"

pkgbuild \
    --component "$APP" \
    --identifier "local.codex.NetSpeedMenu.pkg" \
    --version "$VERSION" \
    --ownership recommended \
    --install-location "/Applications" \
    "$COMPONENT_PACKAGE"

productbuild \
    --package "$COMPONENT_PACKAGE" \
    "$PACKAGE"
cp "$PACKAGE" "$VERSIONED_PACKAGE"

echo "$PACKAGE"
echo "$VERSIONED_PACKAGE"
