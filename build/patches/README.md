# build/patches — Copilot removal patch status

Status: 2026-10-23, pinned upstream tag `1.142.0` (commit d956e8a6), 53 rebase complete + CI-chain verified.

## Files

| File | Kind | Status |
|---|---|---|
| `52-ext-copilot-remove-it.json` | JSON actions (physical removals) | **ENABLED** — 177/177 removal paths verified present on 1.142.0 and applied cleanly |
| `53-ext-copilot-remove-it.patch` | git apply (reference cleanup, 30 files) | **ENABLED (rebase v2)** — regenerated against 1.142.0 + 52; 28 modified + 2 deleted files |

Source: https://github.com/VSCodium/vscodium/tree/master/patches (MIT). Picket applies
52 via `build/apply-patches.sh` (JSON removals) then 53 (git apply) in order.

## 53 rebase v2 (2026-10-23)

Rebased against `microsoft/vscode@1.142.0` (commit d956e8a6) with patch 52 already applied.
Regenerated from the local rebase tree: `git diff HEAD` filtered to exclude the 177 paths
already removed by 52. Result: 28 modified + 2 deleted files (30 `diff --git` headers),
applies cleanly with `git apply --ignore-whitespace --check`.

### What the rebase changed vs the VSCodium original

- **Gulp**: dropped copilot tasks from `build/gulpfile.vscode.ts` (`prepareCopilotRipgrepShimTask`,
  `compileCopilotExtensionBuildTask`) and `build/gulpfile.reh.ts`; removed Copilot/Claude
  SDK deps from `build/npm/postinstall.ts` (`.claude/` symlink block) and `package.json`
  (scripts `compile-copilot` / `watch-copilot`, deps `@anthropic-ai/sdk`,
  `@github/copilot-sdk`, `@vscode/copilot-api`, devDeps `@anthropic-ai/claude-agent-sdk`,
  `@openai/codex`, meta `copilotRuntimeVersion`; codex / agent-host copilot-meta scripts).
- **Locks**: `package-lock.json` / `remote/package-lock.json` regenerated via
  `npm install --package-lock-only --ignore-scripts` after the dependency edits — 0 Copilot
  entries remaining.
- **agentHost core**: `agentHostMain.ts` provider registration block (CopilotAgent
  unconditional + Claude/Codex gated) removed; `agentHostServices.ts` OTel/Claude/Codex
  service registrations removed; `agentService.ts` OTel import/ctor param + session
  comparison metadata call removed; `agentHostTelemetryReporter.ts` OTel import/ctor
  param/`emitTurnTiming` block + codex account telemetry spread removed
  (`isOtelEnabled` fixed to `false`); `protocolServerHandler.ts` OTel imports;
  `agentHostAutomationCustomizations.ts` copilot plugin converter removed
  (`children: []`); `agentServiceTestUtils.ts` OTel/Copilot service removal;
  `agentHostTurnTelemetryContext.ts`, `agentHostBootstrap.ts`, `agentHostContributions.ts`
  reference cleanup.
- **Deleted**: `src/vs/platform/agentHost/node/claude/claudeTerminalOutput.ts` and its test
  (Claude-only terminal renderer; not covered by 52's path list).
- **Skipped (intentionally)**: `agentHostSessionTitleController.ts` — 1.142.0 already uses
  `IAgentHostUtilityModelService` for title generation; the VSCodium 53 hunk (Copilot
  utility-chat + GitHub context) targets an older implementation and is not applicable.
  Non-blocking for compile; leftover Copilot import stays until the P2/G3 byte-cleanup pass.

### Verification

- `git apply -R --check` against the rebase tree: clean.
- Clean-tree forward test: fresh `1.142.0` worktree + 52 (177 removals) + 53 → apply OK,
  no rejects; esbuild error list from CI run #15 (24 dangling imports) fully resolved:
  `copilotAgent`/`claudeAgent`/`codex*`/`agentHostOTelService`/`codexAccountTelemetry`/
  `codexSavedChatReader`/`agentHostCommitOperationProvider`/`claudeReplayMapper`/
  `claudeSubagentRegistry`/`claudeToolDisplay`/`copilotSessionLauncher`/
  `copilotPluginConverters` → 0 hits in `src/vs/platform/agentHost/node`.
- Remaining non-blocking references (identical on rebase tree and clean test tree):
  `agentHostServerMain.ts` argv parsing (`--codex-sdk-root`), `nodeAgentHostStarter.ts`
  config reads, `copilotBuiltinAgents.ts` (copilot dir, test-only import), comment in
  `agentSdkDownloader.ts`. All outside the esbuild bundle graph.

## Build order reminder

52 alone removes the providers' sources, so a full compile FAILS until 53 (reference
cleanup) is applied too. Both are now in `apply-list.txt` and run in CI order 52 → 53.
