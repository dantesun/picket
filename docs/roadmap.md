# Roadmap

Aligned with the P0 product analysis (project wiki): **conditional entry, P0 validation first**.

## P0 — validation loop (current)

| # | Capability | Deliverable | Status |
|---|---|---|---|
| 1 | Clean build pipeline | VSCodium-style build pipeline. MVP: telemetry-free binaries for **linux (x64) + win32 (x64)**; macOS planned after P0 validation | In repo — MVP scope: linux + win32 (`build/prepare.sh` + `release.yml`) |
| 2 | iCode first-class integration | Embedded terminal + ACP stdio bridge + preconfigured compliant agent profile | Planned |
| 3 | Private gateway layer | LiteLLM-based gateway packaging + gated marketplace MVP (Open VSX mirror + allowlist) + sandbox profiles with default-deny egress | Planned |

Validation: 10–20 seed users; baseline metric is "install → first task pass rate". No hard thresholds or dates set.

## Non-goals (P0)

- No first-party models.
- No cloud-hosted sandboxes.
- No Microsoft marketplace compatibility.
- No feature race with Cursor on raw intelligence.

## Later

- Packaging upgrades: AppImage / deb, dmg, NSIS installer, code signing.
- macOS (darwin) builds added to the release matrix after P0 validation.
- ARM64 builds in CI matrix.
- BYO agent open surface (avoid becoming an iCode-only distribution).
- Verify Microsoft Private Marketplace policy for non-official forks.
