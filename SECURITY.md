# 报告安全问题

如果你在 Picket 中发现安全问题，请通过私密渠道报告，不要公开发 issue。

- **GitHub 私密漏洞报告**：使用仓库 Security 标签页的「Report a vulnerability」按钮。
- 请包含：受影响版本、平台、复现步骤、影响范围。

我们会保密处理安全报告，并在 3 个工作日内确认收到。

## 沙箱注意

Picket 的构建本身不会对任意代码做沙箱隔离：扩展与 agent 的 skill 脚本以你的用户权限运行。请在 agent 工作负载中使用按项目的 devcontainer 与出站防火墙配置，并在安装前审查第三方扩展与 skill。
