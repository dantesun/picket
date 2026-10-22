# Picket

> 面向 AI 编码 agent 的加固版 VS Code 发行版——受控扩展、私有模型网关、按项目沙箱，开箱即用。

Picket 是 [Code - OSS](https://github.com/microsoft/vscode) 的发行版（fork），以干净、无遥测的二进制分发。它面向在可信、按项目隔离的环境中运行 AI 编码 agent（Claude Code、OpenCode、[iCode](https://github.com/openJiuwen-ai/iCode)）的团队——典型场景是企业 / 信创内网。

## 特性

- **干净发行**——MIT 许可的 Code-OSS 构建，移除微软定制（无遥测、无微软品牌、无微软市场）。
- **默认离线**——发行版不包含任何需要联网的扩展：无 Copilot、无 GitHub 云集成、无认证/隧道/浏览器扩展；核心编辑体验完全离线。
- **受控扩展**——默认使用 Open VSX，可指向自建市场；可在其上叠加白名单策略。
- **私有模型网关**——设计上配合自托管网关（如 LiteLLM），让 agent 只访问你控制的模型端点。
- **按项目沙箱**——devcontainer 模板与出站防火墙配置，把 agent 的终端、构建与文件操作约束在项目内。
- **iCode 一等公民支持**——预置 iCode 作为内置编码 agent（BYO 模型、无遥测、OTel 就绪、支持 Workflows 与 Skills）。

## 平台支持

MVP 范围（当前发行）：**Linux (x64)** 与 **Windows (x64)**——`tar.gz` 与 `zip` 压缩包。macOS 与 ARM64 在 P0 验证闭环后规划；见 `docs/roadmap.md`。

## 快速开始

从 [Releases](https://github.com/dantesun/picket/releases) 下载对应平台的压缩包，解压后运行 `picket`（Windows：`picket.exe`）。

首次启动 iCode 时按 **F4** 添加模型配置。

## 从源码构建

```bash
bash build/prepare.sh <vscode-version> <picket-version> <linux|darwin|win32> [x64|arm64]
```

示例：

```bash
bash build/prepare.sh 1.99.1 0.1.0 linux x64
```

脚本会克隆 `microsoft/vscode@<vscode-version>`、合并打补丁 `build/product.json`（改名、关闭遥测、Open VSX 市场、更新通道指向本项目 Releases）、按最小集裁剪内置扩展、构建并打包目标平台二进制。

## 发行流水线

推送 `v*` 标签即触发 GitHub Actions 发行工作流（`.github/workflows/release.yml`）：

1. 在解析出的上游标签处克隆 `microsoft/vscode`。
2. 应用 `build/product.json`——改名为 Picket、关闭遥测、Open VSX 市场、更新通道指向本项目 Releases。
3. 按最小集裁剪内置扩展（`build/extensions-remove.list`，默认离线）。
4. 按平台构建（linux / win32，x64——MVP 范围）并打包（`tar.gz` / `zip`）。
5. 将产物发布到 GitHub Release。

计划中的打包升级：AppImage 与 deb、dmg、NSIS 安装器、代码签名。见 `docs/roadmap.md`。

## 许可

本仓库为 MIT 许可。发行的二进制由 `microsoft/vscode`（MIT）构建，与 [VSCodium](https://vscodium.com) 采用相同模式。

> Picket 与微软无关。“Visual Studio Code”是微软的商标。本项目仅使用开源的 Code - OSS 源码。
