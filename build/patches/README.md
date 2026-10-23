# build/patches — Copilot removal patch status

Status: 2026-10-23, pinned upstream tag `1.142.0` (commit d956e8a6), local verification run.

## Files

| File | Kind | Status |
|---|---|---|
| `52-ext-copilot-remove-it.json` | JSON actions (physical removals) | **ENABLED** — 177/177 removal paths verified present on 1.142.0 and applied cleanly in local verification |
| `53-ext-copilot-remove-it.patch` | git apply (reference cleanup, 26 files) | **STORED, NOT ENABLED** — needs rebase to 1.142.0 (see below) |

Source: https://github.com/VSCodium/vscodium/tree/master/patches (MIT). VSCodium applies
both patches in order after its branding/telemetry patches; Picket applies 52 via
`build/apply-patches.sh` and 53 once rebased.

## Why 53 is not enabled yet

`git apply --check` against `microsoft/vscode@1.142.0` fails on the following files
(recorded 2026-10-23). VSCodium's master branch tracks a newer upstream commit, so the
patch context drifted:

```
build/gulpfile.reh.ts
build/gulpfile.vscode.ts
build/npm/postinstall.ts
package-lock.json
package.json
remote/package-lock.json
remote/package.json
src/vs/platform/agentHost/node/agentHostBootstrap.ts
src/vs/platform/agentHost/node/agentHostMain.ts
src/vs/platform/agentHost/node/agentHostServices.ts
(+ other agentHost / copilot SDK files; full list = the 26 files in the patch)
```

## Rebase steps (P2 first task)

1. Checkout the pinned tree and run `git apply --reject --ignore-whitespace 53-ext-copilot-remove-it.patch`.
2. Fix each `.rej` hunk by hand against the current 1.142.0 sources; verify the intent
   matches the VSCodium original (removing Copilot/Claude/Codex/OTel registration blocks,
   SDK deps, gulp copilot tasks, `providerConfigurations: []`).
3. Regenerate the patch: `git diff > 53-ext-copilot-remove-it.patch` and replace this file.
4. Add `53-ext-copilot-remove-it.patch` to `apply-list.txt` and run a full build.

Note: 52 alone removes the providers' sources, so a full compile will FAIL until 53
(reference cleanup) is applied too. Do not expect a green build between 52 and 53.
