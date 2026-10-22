#!/usr/bin/env bash
# Compile stage of the Picket build (mirrors VSCodium build.sh in CI mode).
#
# Usage: build.sh <vscode-version> <picket-version> <linux|win32> [x64|arm64]
#
# Stages: clone microsoft/vscode at the pinned tag, trim built-in extensions,
# apply Picket patches (product.json merge + Copilot removal), npm ci (retry),
# then run the shared upstream `vscode-min-prepack` gulp task. The vscode/ tree
# is compressed into vscode.tar.gz (excluding node_modules/.build/node/.git)
# and consumed by the per-platform package job, exactly like VSCodium's CI.
set -euo pipefail

VSCODE_VERSION="$1"
PICKET_VERSION="$2"
PLATFORM="${3:-linux}"
ARCH="${4:-x64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

case "$PLATFORM" in
  linux|win32) ;;
  *) echo "Unknown platform: $PLATFORM (expected linux|win32)" >&2; exit 1 ;;
esac

case "$ARCH" in
  x64|arm64) ;;
  *) echo "Unknown arch: $ARCH (expected x64|arm64)" >&2; exit 1 ;;
esac

echo "==> [picket] Cloning microsoft/vscode@$VSCODE_VERSION"
rm -rf "$ROOT_DIR/vscode"
git clone --depth 1 --branch "$VSCODE_VERSION" \
  https://github.com/microsoft/vscode.git "$ROOT_DIR/vscode"

echo "==> [picket] Trimming built-in extensions to the minimal set"
cd "$ROOT_DIR/vscode"
REMOVE_COUNT=0
while IFS= read -r ext; do
  [ -z "$ext" ] && continue
  ext="${ext%$'\r'}"
  if [ -d "extensions/$ext" ]; then
    rm -rf "extensions/$ext"
    REMOVE_COUNT=$((REMOVE_COUNT + 1))
  fi
done < "$SCRIPT_DIR/extensions-remove.list"
echo "Removed $REMOVE_COUNT built-in extension dirs (see build/extensions-remove.list)"

echo "==> [picket] Applying Picket patches (product.json, Copilot, extension lists)"
python3 "$SCRIPT_DIR/patch-vscode.py"

echo "==> [picket] Installing dependencies (npm ci; upstream no longer supports yarn)"
for i in 1 2 3 4 5; do
  npm ci --no-audit --no-fund && break
  if [ "$i" -eq 5 ]; then
    echo "npm ci failed too many times" >&2
    exit 1
  fi
  echo "npm ci failed $i, retrying..."
  sleep $(( 15 * (i + 1) ))
done

echo "==> [picket] Shared prepack (vscode-min-prepack)"
export NODE_OPTIONS="--max-old-space-size=8192"
npm run gulp vscode-min-prepack

echo "==> [picket] Compressing vscode/ for the package stage"
cd "$ROOT_DIR"
# Same exclusions as VSCodium's compile job: keep compiled sources, drop
# node_modules / .build/node / .git (the package stage re-runs npm ci).
find vscode -type f \
  -not -path "*/node_modules/*" \
  -not -path "vscode/.build/node/*" \
  -not -path "vscode/.git/*" > vscode.txt
echo "vscode/.build/extensions/node_modules" >> vscode.txt
echo "vscode/.git" >> vscode.txt
tar -czf "vscode.tar.gz" -T vscode.txt

echo "==> [picket] Compile stage done. Picket v$PICKET_VERSION ($PLATFORM-$ARCH) from VS Code $VSCODE_VERSION"
ls -lh "$ROOT_DIR/vscode.tar.gz"
