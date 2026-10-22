# Reporting Security Issues

If you discover a security issue in Picket, please report it privately instead of opening a public issue.

- **GitHub private vulnerability reporting**: use the "Report a vulnerability" button on the repository's Security tab.
- Include: affected version, platform, reproduction steps, and impact.

We treat security reports confidentially and will acknowledge receipt within 3 business days.

## Sandbox caveat

Picket's build does not sandbox arbitrary code: extensions and agent skill scripts run with your user permissions. Use the per-project devcontainer + egress firewall profiles for agent workloads and review third-party extensions and skills before installing.
