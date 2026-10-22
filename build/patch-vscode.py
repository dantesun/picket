#!/usr/bin/env python3
"""Picket patches for a microsoft/vscode source tree.

Run from the vscode source root. Every patch asserts its anchor text so a
changed upstream version fails loudly instead of silently mis-patching.

Patches:
  1. product.json   - merge build/product.json (rename, telemetry off, Open VSX)
  2. copilot.ts     - make Copilot SDK guard a no-op (Copilot removed)
  3. npm/dirs.ts    - skip removed extension dirs in postinstall
  4. gulpfile.extensions.ts - compile only existing extension tsconfigs
  5. lib/extensions.ts     - build media only for existing extension scripts
  6. gulpfile.vscode.ts    - skip AppX/context-menu packaging when win32ContextMenu is absent
  7. gulpfile.vscode.ts    - tolerate missing signtool.exe (no Authenticode to strip)
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # repo root (picket/)
VSCODE = Path.cwd()  # vscode source root


def patch_file(rel: str, old: str, new: str, what: str) -> None:
    p = VSCODE / rel
    src = p.read_text(encoding='utf-8')
    assert old in src, f'{rel}: {what} anchor not found'
    p.write_text(src.replace(old, new, 1), encoding='utf-8')
    print(f'patched {rel} ({what})')


def main() -> None:
    # 1. product.json merge (keep upstream fields like builtInExtensions)
    product_path = VSCODE / 'product.json'
    patch_path = ROOT / 'build' / 'product.json'
    product = json.loads(product_path.read_text(encoding='utf-8'))
    patch = json.loads(patch_path.read_text(encoding='utf-8'))
    product.update(patch)
    product_path.write_text(json.dumps(product, indent=2, ensure_ascii=False), encoding='utf-8')
    print('patched product.json (keys: ' + ', '.join(sorted(patch)) + ')')

    # 2. copilot.ts: Copilot SDK guard -> no-op
    patch_file(
        'build/lib/copilot.ts',
        'throw new Error(`[prepareBuiltInCopilotRipgrepShim] Copilot SDK directory not found at ${copilotSdkBase}`);',
        'console.warn(`[picket] Copilot extension removed; skipping ripgrep shim: ${copilotSdkBase}`);\n\t\treturn;',
        'prepareBuiltInCopilotRipgrepShim throw -> warn+return',
    )

    # 3. npm/dirs.ts: filter removed extension dirs from postinstall
    patch_file(
        'build/npm/dirs.ts',
        "import { existsSync } from 'fs';",
        "import { existsSync } from 'fs';\nimport path from 'path';",
        'dirs.ts import path',
    )
    patch_file(
        'build/npm/dirs.ts',
        "'.vscode/extensions/vscode-pr-pinger',\n];",
        "'.vscode/extensions/vscode-pr-pinger',\n].filter(dir => dir === '' || existsSync(path.join(import.meta.dirname, '../..', dir)));",
        'dirs.ts filter non-existent dirs',
    )

    # 4. gulpfile.extensions.ts: compile only existing extension tsconfigs
    patch_file(
        'build/gulpfile.extensions.ts',
        "'.vscode/extensions/vscode-pr-pinger/tsconfig.json',\n];",
        "'.vscode/extensions/vscode-pr-pinger/tsconfig.json',\n].filter(f => fs.existsSync(path.join(root, f)));",
        'compilations filter non-existent tsconfigs',
    )

    # 5. lib/extensions.ts: build extension media only for existing scripts
    patch_file(
        'build/lib/extensions.ts',
        "\t{ script: 'simple-browser/esbuild.webview.mts', tsconfig: 'simple-browser/preview-src/tsconfig.json' },\n];",
        "\t{ script: 'simple-browser/esbuild.webview.mts', tsconfig: 'simple-browser/preview-src/tsconfig.json' },\n].filter(({ script, tsconfig }) => fs.existsSync(path.join(extensionsPath, script)) && fs.existsSync(path.join(extensionsPath, tsconfig)));",
        'esbuildMediaScripts filter non-existent scripts',
    )


    # 6. gulpfile.vscode.ts: skip AppX/context-menu packaging (no win32ContextMenu in picket product.json)
    patch_file(
        'build/gulpfile.vscode.ts',
        "if (quality === 'stable' || quality === 'insider') {",
        "if (product.win32ContextMenu && (quality === 'stable' || quality === 'insider')) {",
        'skip appx when win32ContextMenu absent',
    )

    # 7. gulpfile.vscode.ts: treat missing signtool as unsigned, keep rcedit working
    patch_file(
        'build/gulpfile.vscode.ts',
        "const proc = cp.spawn('signtool.exe', ['verify', '/pa', filePath]);\n\t\tproc.on('error', reject);",
        "const proc = cp.spawn('signtool.exe', ['verify', '/pa', filePath]);\n\t\tproc.on('error', () => resolve(false));",
        'signtool missing -> resolve(false)',
    )

    print('All picket patches applied.')



if __name__ == '__main__':
    sys.exit(main())
