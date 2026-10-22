# Picket

> A hardened VS Code distribution for AI coding agents — gated extensions, a private model gateway, and per-project sandboxes, out of the box.

Picket is a [Code - OSS](https://github.com/microsoft/vscode) fork distributed as a clean, telemetry-free binary. It is built for teams that run AI coding agents (Claude Code, OpenCode, [iCode](https://github.com/openJiuwen-ai/iCode)) inside trusted, per-project environments — the typical enterprise / 信创 intranet scenario.

## Features

- **Clean distribution** — MIT-licensed build of Code-OSS with Microsoft customizations removed (no telemetry, no Microsoft branding, no Microsoft marketplace).
- **Gated extensions** — extensions come from Open VSX by default and can point at your own gallery; a whitelist policy can be layered on top.
- **Private model gateway** — designed to pair with a self-hosted gateway (e.g. LiteLLM) so agents only talk to model endpoints you control.
- **Per-project sandboxes** — devcontainer templates and egress firewall profiles keep an agent's terminal, builds and file operations inside the project.
- **First-class iCode support** — preconfigured to run iCode as the built-in coding agent (BYO model, no telemetry, OTel-ready, Workflows & Skills supported).

## Quick start

Download the latest installer/archive for your platform from [Releases](https://github.com/dantesun/picket/releases), unpack and run `picket` (Windows: `picket.exe`).

Press **F4** inside iCode on first launch to add a model profile.

## Build from source

```bash
bash build/prepare.sh <vscode-version> <picket-version> <linux|darwin|win32> [x64|arm64]
```

Example:

```bash
bash build/prepare.sh 1.99.1 0.1.0 linux x64
```

The script clones `microsoft/vscode@<vscode-version>`, applies `build/product.json`, builds and packages the binary for the target platform.

## Release pipeline

Pushing a `v*` tag triggers the GitHub Actions release workflow (`.github/workflows/release.yml`):

1. Clone `microsoft/vscode` at the resolved upstream tag.
2. Apply `build/product.json` — rename to Picket, telemetry off, Open VSX gallery, update channel to our releases.
3. Build per-platform (linux / darwin / win32, x64) and package (`tar.gz` / `zip`).
4. Publish assets to the GitHub Release.

Planned packaging upgrades: AppImage & deb, dmg, NSIS installer, code signing. See `docs/roadmap.md`.

## License

MIT for this repository. The distributed binary is built from `microsoft/vscode` (MIT) and follows the same pattern as [VSCodium](https://vscodium.com).

> Picket is not affiliated with Microsoft. "Visual Studio Code" is a trademark of Microsoft. This project uses the open-source Code - OSS sources only.
