#!/usr/bin/env bash
# Prepare, build and package a Picket release from upstream VS Code.
#
# Usage: prepare.sh <vscode-version> <picket-version> <linux|darwin|win32> [x64|arm64]
#
# Follows the VSCodium pattern: clone microsoft/vscode, patch product.json
# (merge, not overwrite — upstream fields like builtInExtensions must stay),
# trim built-in extensions to the minimal set, patch out upstream Copilot
# build hooks, build with npm/gulp, then package platform artifacts.
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

echo "==> [picket] Patching product.json (rename, telemetry off, Open VSX gallery)"
cd "$ROOT_DIR/vscode"
python3 - "$SCRIPT_DIR/product.json" <<'PYEOF'
import json, sys
patch_path = sys.argv[1]
with open('product.json', encoding='utf-8') as f:
    product = json.load(f)
with open(patch_path, encoding='utf-8') as f:
    patch = json.load(f)
product.update(patch)
with open('product.json', 'w', encoding='utf-8') as f:
    json.dump(product, f, indent=2, ensure_ascii=False)
print('Patched keys:', ', '.join(sorted(patch.keys())))
PYEOF

echo "==> [picket] Trimming built-in extensions to the minimal set"
REMOVE_COUNT=0
while IFS= read -r ext; do
  [ -z "$ext" ] && continue
  if [ -d "extensions/$ext" ]; then
    rm -rf "extensions/$ext"
    REMOVE_COUNT=$((REMOVE_COUNT + 1))
  fi
done < "$SCRIPT_DIR/extensions-remove.list"
echo "Removed $REMOVE_COUNT built-in extension dirs (see build/extensions-remove.list)"

echo "==> [picket] Patching out upstream Copilot build hooks (1.142 hardcodes Copilot)"
python3 - <<'PYEOF'
# Upstream 1.142 hard-codes the built-in Copilot extension into the min
# packaging chain: prepareBuiltInCopilotRipgrepShim throws when
# extensions/copilot/node_modules/@github/copilot/sdk is missing. Since
# Picket removes Copilot entirely, make the guard a no-op.
path = 'build/lib/copilot.ts'
with open(path, encoding='utf-8') as f:
    src = f.read()
old = 'throw new Error(`[prepareBuiltInCopilotRipgrepShim] Copilot SDK directory not found at ${copilotSdkBase}`);'
new = 'console.warn(`[picket] Copilot extension removed; skipping ripgrep shim: ${copilotSdkBase}`);\n\t\treturn;'
assert old in src, 'copilot.ts: prepareBuiltInCopilotRipgrepShim throw not found'
src = src.replace(old, new, 1)
with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print('patched build/lib/copilot.ts (throw -> warn+return)')
PYEOF

echo "==> [picket] Installing dependencies (npm ci; upstream no longer supports yarn)"
npm ci --no-audit --no-fund

case "$PLATFORM" in
  linux)  TARGET="vscode-linux-$ARCH-min"  ;;
  darwin) TARGET="vscode-darwin-$ARCH-min" ;;
  win32)  TARGET="vscode-win32-$ARCH-min"  ;;
esac

echo "==> [picket] Building $TARGET"
export NODE_OPTIONS="--max-old-space-size=8192"
npm run gulp "$TARGET"

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
