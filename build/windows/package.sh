#!/usr/bin/env bash
# Windows package stage (mirrors VSCodium build/windows/package.sh, scoped to
# the Picket MVP): extract the compile artifact, npm ci (retry), drop stale
# native .node files, generate Group Policy definitions, run the upstream
# `vscode-win32-x64-min-packing` gulp task, rename to picket-win32-* (with
# Windows file-lock resilience), archive as zip.
#
# Deviations from VSCodium: no distro mixin (Picket patches product.json at
# compile time), no installer/signing/MSI (MVP ships the raw zip), no REH.
set -euo pipefail

PLATFORM="${1:-win32}"
ARCH="${2:-x64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> [picket] Locating compile artifact"
TARBALL="$(find "$ROOT_DIR" -maxdepth 2 -name 'vscode.tar.gz' | head -1)"
if [ -z "$TARBALL" ]; then
  echo "vscode.tar.gz not found" >&2
  exit 1
fi
tar -xzf "$TARBALL" -C "$ROOT_DIR"

cd "$ROOT_DIR/vscode"

export VSCODE_PLATFORM='win32'
export NODE_OPTIONS="--max-old-space-size=8192"

for i in 1 2 3 4 5; do
  npm ci --prefix build --no-audit --no-fund && break
  if [ "$i" -eq 5 ]; then
    echo "npm ci (build) failed too many times" >&2
    exit 1
  fi
  echo "npm ci (build) failed $i, retrying..."
  sleep $(( 15 * (i + 1) ))
done

for i in 1 2 3 4 5; do
  npm ci --no-audit --no-fund && break
  if [ "$i" -eq 5 ]; then
    echo "npm ci failed too many times" >&2
    exit 1
  fi
  echo "npm ci failed $i, retrying..."
  sleep $(( 15 * (i + 1) ))
done

# delete native files built in the compile step (same as VSCodium)
find .build/extensions -type f -name '*.node' -print -delete

# generate Group Policy definitions (same as VSCodium)
npm run copy-policy-dto --prefix build
node build/lib/policies/policyGenerator.ts build/lib/policies/policyData.jsonc win32

npm run gulp "vscode-win32-$ARCH-min-packing"

echo "==> [picket] Renaming to picket-win32-$ARCH"
cd "$ROOT_DIR"
OUT_DIR="picket-win32-$ARCH"
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

echo "==> [picket] Archiving as zip"
if command -v 7z >/dev/null 2>&1; then
  (cd "$OUT_DIR" && 7z a -tzip "$ROOT_DIR/picket-win32-$ARCH.zip" . >/dev/null)
elif [ -x "/c/Program Files/7-Zip/7z.exe" ]; then
  (cd "$OUT_DIR" && "/c/Program Files/7-Zip/7z.exe" a -tzip "$ROOT_DIR/picket-win32-$ARCH.zip" . >/dev/null)
else
  powershell -NoProfile -Command "Compress-Archive -Force -Path './$OUT_DIR/*' -DestinationPath '$ROOT_DIR/picket-win32-$ARCH.zip'"
fi

echo "==> [picket] Windows package done"
ls -lh "$ROOT_DIR/picket-win32-$ARCH.zip"
