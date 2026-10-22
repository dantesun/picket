#!/usr/bin/env bash
# Linux package stage (mirrors VSCodium build/linux/package_bin.sh, scoped to
# the Picket MVP): extract the compile artifact, npm ci (retry), drop stale
# native .node files, generate Group Policy definitions, run the upstream
# `vscode-linux-x64-min-packing` gulp task, rename to picket-linux-*, archive.
#
# Deviations from VSCodium (documented): no distro mixin (Picket patches
# product.json at compile time), no REH/CLI packages (MVP scope), no custom
# sysroot build agent (hosted runner toolchain).
set -euo pipefail

PLATFORM="${1:-linux}"
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

export VSCODE_PLATFORM='linux'
export VSCODE_SKIP_NODE_VERSION_CHECK=1
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
node build/lib/policies/policyGenerator.ts build/lib/policies/policyData.jsonc linux

npm run gulp "vscode-linux-$ARCH-min-packing"

find "../VSCode-linux-$ARCH" -print0 | xargs -0 touch -c

echo "==> [picket] Renaming to picket-linux-$ARCH"
cd "$ROOT_DIR"
OUT_DIR="picket-linux-$ARCH"
rm -rf "$OUT_DIR"
mv "VSCode-linux-$ARCH" "$OUT_DIR"

echo "==> [picket] Archiving"
tar czf "$ROOT_DIR/picket-linux-$ARCH.tar.gz" "$OUT_DIR"

echo "==> [picket] Linux package done"
ls -lh "$ROOT_DIR/picket-linux-$ARCH.tar.gz"
