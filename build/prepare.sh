#!/usr/bin/env bash
# Prepare, build and package a Picket release from upstream VS Code.
#
# Usage: prepare.sh <vscode-version> <picket-version> <linux|darwin|win32> [x64|arm64]
#
# Follows the VSCodium pattern: clone microsoft/vscode, lay down our
# product.json, build with gulp, then package platform artifacts.
set -euo pipefail

VSCODE_VERSION="$1"
PICKET_VERSION="$2"
PLATFORM="${3:-linux}"
ARCH="${4:-x64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

case "$PLATFORM" in
  linux|darwin|win32) ;;
  *) echo "Unknown platform: $PLATFORM (expected linux|darwin|win32)" >&2; exit 1 ;;
esac

case "$ARCH" in
  x64|arm64) ;;
  *) echo "Unknown arch: $ARCH (expected x64|arm64)" >&2; exit 1 ;;
esac

echo "==> [picket] Cloning microsoft/vscode@$VSCODE_VERSION"
rm -rf "$ROOT_DIR/vscode"
git clone --depth 1 --branch "$VSCODE_VERSION" \
  https://github.com/microsoft/vscode.git "$ROOT_DIR/vscode"

echo "==> [picket] Applying product.json (rename, telemetry off, Open VSX gallery)"
cp "$SCRIPT_DIR/product.json" "$ROOT_DIR/vscode/product.json"

echo "==> [picket] Installing dependencies (yarn 1)"
cd "$ROOT_DIR/vscode"
npm install -g yarn@1.22.22
yarn --ignore-optional

case "$PLATFORM" in
  linux)  TARGET="vscode-linux-$ARCH-min"  ;;
  darwin) TARGET="vscode-darwin-$ARCH-min" ;;
  win32)  TARGET="vscode-win32-$ARCH-min"  ;;
esac

echo "==> [picket] Building $TARGET"
export NODE_OPTIONS="--max-old-space-size=8192"
node node_modules/.bin/gulp "$TARGET"

echo "==> [picket] Packaging"
cd "$ROOT_DIR/vscode"
case "$PLATFORM" in
  linux)
    OUT_DIR="picket-linux-$ARCH"
    rm -rf "$OUT_DIR"
    mv "vscode-linux-$ARCH" "$OUT_DIR"
    tar czf "$ROOT_DIR/picket-linux-$ARCH.tar.gz" "$OUT_DIR"
    ;;
  darwin)
    APP="$(find . -maxdepth 3 -name "*.app" | head -1)"
    if [ -z "$APP" ]; then echo "No .app bundle found" >&2; exit 1; fi
    BUNDLE_DIR="$(dirname "$APP")"
    rm -rf "$BUNDLE_DIR/Picket.app"
    mv "$APP" "$BUNDLE_DIR/Picket.app"
    (cd "$BUNDLE_DIR" && zip -qr "$ROOT_DIR/picket-darwin-$ARCH.zip" "Picket.app")
    ;;
  win32)
    OUT_DIR="picket-win32-$ARCH"
    rm -rf "$OUT_DIR"
    mv "vscode-win32-$ARCH" "$OUT_DIR"
    if command -v powershell >/dev/null 2>&1; then
      powershell -NoProfile -Command "Compress-Archive -Force -Path './$OUT_DIR' -DestinationPath '$ROOT_DIR/picket-win32-$ARCH.zip'"
    else
      zip -qr "$ROOT_DIR/picket-win32-$ARCH.zip" "$OUT_DIR"
    fi
    ;;
esac

echo "==> [picket] Done. Picket v$PICKET_VERSION ($PLATFORM-$ARCH) built from VS Code $VSCODE_VERSION"
ls -lh "$ROOT_DIR" | grep -E 'picket-(linux|darwin|win32)' || true
