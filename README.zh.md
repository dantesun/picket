# Picket

> 面向 AI 编码 agent 的加固版 VS Code 分发版 —— gated 扩展市场、私有模型网关、按项目隔离沙箱，开箱即用。

Picket 是基于 [Code - OSS](https://github.com/microsoft/vscode) fork 的干净、去遥测二进制分发版。它面向在企业（尤其信创内网）环境中、在可信的按项目隔离环境里运行 AI 编码 agent（Claude Code、OpenCode、[iCode](https://github.com/openJiuwen-ai/iCode)）的团队。

## 特性

- **干净分发**：MIT 许可的 Code-OSS 构建，移除微软定制（无遥测、无微软品牌、无微软市场）。
- **Gated 扩展**：默认接 Open VSX，可指向自建 gallery；可叠加白名单策略。
- **私有模型网关**：设计上与自托管网关（如 LiteLLM）配合，agent 只访问你控制的模型端点。
- **按项目沙箱**：devcontainer 模板与出站防火墙配置，把 agent 的终端、构建、文件操作约束在项目内。
- **首发深度支持 iCode**：预配置把 [iCode](https://github.com/openJiuwen-ai/iCode) 作为内置编码 agent（BYO 模型、无遥测、OTel 就绪、支持 Workflows 与 Skills）。

## 平台支持

MVP 范围（当前发行）：**Linux (x64)** 与 **Windows (x64)** —— `tar.gz` / `zip` 压缩包。macOS 与 ARM64 构建计划在 P0 验证循环之后补充，见 `docs/roadmap.md`。

## 快速开始

从 [Releases](https://github.com/dantesun/picket/releases) 下载对应平台的压缩包，解压后运行 `picket`（Windows 为 `picket.exe`）。
首次启动 iCode 后按 **F4** 添加模型配置。

## 从源码构建

```bash
bash build/prepare.sh <vscode-version> <picket-version> <linux|darwin|win32> [x64|arm64]
```

示例：

```bash
bash build/prepare.sh 1.99.1 0.1.0 linux x64
```

脚本会克隆 `microsoft/vscode@<vscode-version>`，应用 `build/product.json`，构建并打包目标平台二进制。

## 版本发行流水线

推送 `v*` tag 触发 GitHub Actions 发行工作流（`.github/workflows/release.yml`）：

1. 克隆 `microsoft/vscode`（解析上游 tag）。
2. 应用 `build/product.json` —— 改名 Picket、关闭遥测、接入 Open VSX、更新通道指向本项目 Releases。
3. 按平台构建（linux / win32，x64 —— MVP 范围）并打包（`tar.gz` / `zip`）。
4. 发布资产到 GitHub Release。

计划中的打包升级：AppImage 与 deb、dmg、NSIS 安装器、代码签名。见 `docs/roadmap.md`。

## 许可证

本仓库为 MIT。分发二进制基于 `microsoft/vscode`（MIT）构建，与 [VSCodium](https://vscodium.com) 同一模式。

> Picket 与微软无关。"Visual Studio Code" 是微软商标。本项目仅使用开源的 Code - OSS 源码。
