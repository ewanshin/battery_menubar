#!/bin/bash
# Build BatteryMenubar.app into ./build. Pass --zip to also produce build/BatteryMenubar.zip.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BatteryMenubar"
VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.0.0}"
OUT="build"
APP="$OUT/$APP_NAME.app"

echo "==> Building $APP_NAME $VERSION"
swift build -c release 2>&1 | grep -v '^\[' || true
BIN_DIR="$(swift build -c release --show-bin-path)"
test -x "$BIN_DIR/$APP_NAME"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/"
sed "s/__VERSION__/$VERSION/g" Packaging/Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> Signing (ad-hoc)"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"

if [[ "${1:-}" == "--zip" ]]; then
    echo "==> Zipping"
    rm -f "$OUT/$APP_NAME.zip"
    ditto -c -k --keepParent "$APP" "$OUT/$APP_NAME.zip"
    ls -lh "$OUT/$APP_NAME.zip"
fi

echo "==> Done: $APP"
