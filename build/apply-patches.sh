#!/usr/bin/env bash
# Apply Picket Code / VSCodium patches to a vscode source tree.
#
# Usage: apply-patches.sh [vscode-source-dir]   (default: current directory)
#
# Two patch kinds, applied in order:
#   1. JSON actions (*.json in build/patches/) - physical removals, VSCodium
#      semantics: every remove path MUST exist, otherwise exit 4.
#   2. git apply patches listed in build/patches/apply-list.txt (one filename
#      per line, '#' comments allowed) - applied with --ignore-whitespace.
#      A patch that does not apply exits 1 and prints the failing files.
#
# Patches in build/patches/ that are NOT listed in apply-list.txt are stored
# but not applied yet (see build/patches/README.md for status).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
VSCODE="${1:-$(pwd)}"
cd "$VSCODE"

echo "==> [picket-code] Patching vscode tree at $VSCODE"

# ---- 1. JSON actions (physical removals, VSCodium semantics) ----
for f in "$PATCHES_DIR"/*.json; do
  [ -e "$f" ] || continue
  echo "==> [picket-code] JSON actions: $(basename "$f")"
  python3 - "$f" <<'PYEOF'
import json, os, shutil, sys
manifest = json.load(open(sys.argv[1]))
for action in manifest:
    if action.get("action") != "remove":
        print(f"WARN: unsupported action {action.get('action')}", file=sys.stderr)
        continue
    for p in action.get("paths", []):
        if not os.path.exists(p):
            print(f"FATAL: {p} does not exist (removal failed)", file=sys.stderr)
            sys.exit(4)
        if os.path.isdir(p):
            shutil.rmtree(p)
        else:
            os.remove(p)
        print(f"  removed {p}")
PYEOF
done

# ---- 2. git apply patches (whitelist) ----
APPLY_LIST="$PATCHES_DIR/apply-list.txt"
if [ -f "$APPLY_LIST" ]; then
  while IFS= read -r patch; do
    patch="$(echo "$patch" | sed 's/\r$//')"
    [ -z "$patch" ] && continue
    case "$patch" in \#*) continue;; esac
    echo "==> [picket-code] git apply: $patch"
    if ! git apply --ignore-whitespace --check "$PATCHES_DIR/$patch" 2>"$PATCHES_DIR/.check.err"; then
      echo "FATAL: $patch does not apply to this tree" >&2
      grep '^error:' "$PATCHES_DIR/.check.err" | head -20 >&2 || true
      rm -f "$PATCHES_DIR/.check.err"
      exit 1
    fi
    rm -f "$PATCHES_DIR/.check.err"
    git apply --ignore-whitespace "$PATCHES_DIR/$patch"
  done < "$APPLY_LIST"
fi

echo "==> [picket-code] All patches applied."
