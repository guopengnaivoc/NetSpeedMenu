#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
APP="$ROOT/outputs/网速.app"
PACKAGE="$ROOT/outputs/网速安装器.pkg"
COMPONENT_PACKAGE="$ROOT/work/NetSpeedMenu-component.pkg"

"$ROOT/build-app.sh"

mkdir -p "$ROOT/work"
rm -f "$COMPONENT_PACKAGE" "$PACKAGE"

pkgbuild \
    --component "$APP" \
    --identifier "local.codex.NetSpeedMenu.pkg" \
    --version "1.2" \
    --ownership recommended \
    --install-location "/Applications" \
    "$COMPONENT_PACKAGE"

productbuild \
    --package "$COMPONENT_PACKAGE" \
    "$PACKAGE"

echo "$PACKAGE"
