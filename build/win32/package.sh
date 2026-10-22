#!/usr/bin/env bash
# Package stage for Windows (aligned with the VSCodium pipeline).
#
# Usage: package.sh <vscode-version> <picket-version> <win32> [x64|arm64]
#
# Expects vscode.tar.gz (produced by the compile job) in the repo root.
# Renames the prebuilt VSCode-win32-<arch> folder to picket-win32-<arch>
# and creates a zip. Windows rename is hardened: kill processes locking
# the tree, clear read-only attributes, retry, robocopy /MOVE fallback.
set -euo pipefail

VSCODE_VERSION="$1"
PICKET_VERSION="$2"
PLATFORM="${3:-win32}"
ARCH="${4:-x64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

case "$PLATFORM" in
  win32) ;;
  *) echo "Unknown platform: $PLATFORM (expected win32)" >&2; exit 1 ;;
esac

case "$ARCH" in
  x64|arm64) ;;
  *) echo "Unknown arch: $ARCH (expected x64|arm64)" >&2; exit 1 ;;
esac

echo "==> [picket] Extracting compile artifact (vscode.tar.gz)"
tar -xzf "$ROOT_DIR/vscode.tar.gz"

SRC_DIR="$ROOT_DIR/VSCode-win32-$ARCH"
if [ ! -d "$SRC_DIR" ]; then
  echo "Missing build output: $SRC_DIR" >&2
  exit 1
fi

OUT_DIR="picket-win32-$ARCH"
echo "==> [picket] Packaging (win32-$ARCH) -> $OUT_DIR"
cd "$ROOT_DIR"
rm -rf "$OUT_DIR"

# Windows 下 mv 报 Permission denied 的常见根因：文件被残留进程占用、
# 只读属性、或 Defender 实时扫描的瞬时文件锁。先处理前两类，再带重试
# 移动，最后用 robocopy /MOVE 兜底。
powershell -NoProfile -Command \
  "Get-Process | Where-Object { \$_.Path -like '*VSCode-win32-$ARCH*' } | Stop-Process -Force -ErrorAction SilentlyContinue" || true
powershell -NoProfile -Command "attrib -R 'VSCode-win32-$ARCH\*.*' /S /D" || true
MOVED=0
for i in 1 2 3 4 5; do
  if mv "VSCode-win32-$ARCH" "$OUT_DIR" 2>/dev/null; then
    MOVED=1
    break
  fi
  echo "move retry $i/5 (Windows rename failure is usually transient)..." >&2
  sleep 3
done
if [ "$MOVED" -ne 1 ]; then
  echo "mv retries exhausted; trying robocopy /MOVE fallback..." >&2
  robocopy "VSCode-win32-$ARCH" "$OUT_DIR" /E /MOVE /R:3 /W:2 >/dev/null || true
  [ -d "$OUT_DIR" ] && MOVED=1
fi
if [ "$MOVED" -ne 1 ]; then
  echo "failed to move VSCode-win32-$ARCH to $OUT_DIR" >&2
  exit 1
fi

echo "==> [picket] Creating picket-win32-$ARCH.zip"
if command -v 7z >/dev/null 2>&1; then
  7z a -r -tzip "$ROOT_DIR/picket-win32-$ARCH.zip" "$OUT_DIR"
elif [ -x /c/Windows/System32/tar.exe ]; then
  /c/Windows/System32/tar.exe -a -c -f "$ROOT_DIR/picket-win32-$ARCH.zip" "$OUT_DIR"
else
  powershell -NoProfile -Command "Compress-Archive -Force -Path './$OUT_DIR' -DestinationPath '$ROOT_DIR/picket-win32-$ARCH.zip'"
fi

echo "==> [picket] Done. Picket v$PICKET_VERSION (win32-$ARCH) from VS Code $VSCODE_VERSION"
