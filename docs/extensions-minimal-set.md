# Built-in Extension Minimal Set

Picket ships a **minimal set** of built-in extensions to reduce attack surface,
remove Microsoft/Copilot-related components and telemetry, and shrink the
distribution. Removed extensions can be re-installed on demand from the gated
gallery (Open VSX mirror) — see P0-3.

Source of truth: upstream `microsoft/vscode@1.142.0` `extensions/` (97 dirs) +
`product.json` `builtInExtensions` (3 downloaded JS-debug extensions).

## Decision principles

1. **Keep what the editor cannot live without**: language services for the
   core web stack (TS/JS, JSON, CSS, HTML, Markdown), Git integration,
   configuration/extension editing, references/search/merge/debug basics,
   themes/icons, JS debugging (downloaded trio).
2. **Remove everything Microsoft/cloud**: `copilot` (GitHub Copilot Chat),
   `microsoft-authentication` — incompatible with 信创 / intranet / no-telemetry.
3. **Remove internal test extensions**: `vscode-*` test/colorize/api extensions.
4. **Remove non-core language grammars & toolchains**: on-demand install from
   the gated gallery instead of shipping in the base distribution.
5. **Remove redundant themes** except defaults + modern icons.

## Minimal set (kept: 37)

### Core (34, in-repo dirs)

| Extension | Role |
|---|---|
| configuration-editing | settings & JSON editing helpers |
| extension-editing | extension config editing |
| emmet | fast HTML/CSS authoring |
| references-view | find references / implementations |
| search-result | search results browser |
| merge-conflict | merge conflict handling |
| debug-auto-launch | auto node debug |
| debug-server-ready | server-ready debugger |
| media-preview | media preview |
| simple-browser | embedded browser |
| markdown-basics | Markdown grammar |
| markdown-language-features | Markdown language service |
| markdown-math | math in Markdown |
| mermaid-markdown-features | Mermaid diagrams in Markdown |
| prompt-basics (prompt) | prompt-file grammar |
| theme-defaults | light+dark default themes |
| theme-modern-icons | icon theme |
| git / git-base | version control |
| github | GitHub issues/PR panels |
| github-authentication | GitHub auth |
| npm | npm script runner |
| terminal-suggest | terminal completions |
| tunnel-forwarding | port forwarding |
| ipynb / notebook-renderers | notebook support |
| typescript-basics / typescript-language-features / javascript | TS/JS stack |
| types | built-in type declarations |
| css / css-language-features | CSS stack |
| html / html-language-features | HTML stack |
| json / json-language-features | JSON stack |

### Downloaded at build (3)

- ms-vscode.js-debug, ms-vscode.js-debug-companion, ms-vscode.vscode-js-profile-table

## Removed (60) — categories

| Category | Count | Examples | Reinstallable? |
|---|---|---|---|
| Language grammars | 41 | python, php, shellscript, sql, go, rust, java, cpp, … | Yes, from gallery |
| Toolchains | 4 | grunt, gulp, jake, docker | Yes |
| Microsoft/cloud (must remove) | 2 | copilot, microsoft-authentication | No — excluded by policy |
| Internal tests | 4 | vscode-api-tests, vscode-colorize-tests, vscode-colorize-perf-tests, vscode-test-resolver | No |
| Extra themes | 9 | theme-monokai, theme-seti, theme-solarized-*, … | Yes |

## Mechanics

- `build/extensions-remove.list` — one extension dir name per line; `prepare.sh`
  deletes those dirs from the cloned vscode tree before `npm ci` / `gulp`.
- JS-debug trio is configured via `product.json` `builtInExtensions` and stays.
- To restore an extension for a build: comment/remove its line in
  `build/extensions-remove.list` (or install from gallery in the final artifact)
  and rebuild.

## Next steps

- Wire the same list into the gated gallery allowlist (P0-3).
- Re-verify build with the trimmed tree on the next release tag.
