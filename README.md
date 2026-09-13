# Dotfiles

这是使用 Chezmoi 管理 macOS 与 Omarchy/Linux 机器的配置仓库。
仓库明确维护平台差异、软件包归属、加密配置和机器本地数据，而不是直接复制某一台机器的整个 home 目录。

## 快速开始

在新机器上安装 chezmoi 并初始化本仓库：

```bash
chezmoi init --apply https://github.com/happyhaha1/dotfiles.git
```

交互式初始化时，选择机器 profile，并选择这台机器是否拥有共享的 age/SSH 密钥。
age 身份文件应位于：

```text
~/.ssh/main
```

在已有机器上，先检查再谨慎应用：

```bash
chezmoi update
chezmoi diff
chezmoi apply
```

运行本地健康检查：

```bash
just doctor
just check
```

## 机器 Profile

持久化的 chezmoi 数据会选择模板和安装脚本使用的 profile：

- `daily`：普通的交互式 Mac profile。
- `home-server`：减少桌面配置的 macOS 服务器 profile。
- `office-server`：办公室/服务器 profile；Collie 局域网集成目前在此 profile 启用。
- `other`：非交互式或无法分类机器的安全默认 profile。

Collie 局域网地址等机器私有数据保存在本机 chezmoi 配置中（使用 `chezmoi edit-config` 设置），
不会写入 `.chezmoidata/` 或普通的 Git 跟踪模板。

## 软件包归属

按照依赖类型使用对应的软件包管理器：

| 管理器 | 负责内容 | 配置来源 |
| --- | --- | --- |
| Homebrew | macOS formula、cask、字体和 App Store 应用 | `.chezmoidata/homebrew.yaml` |
| Aqua | 固定版本的可移植 CLI 二进制文件 | `private_dot_config/aquaproj-aqua/aqua.yaml` |
| mise | 语言运行时和选定的运行时工具 | `private_dot_config/mise/config.toml.tmpl` |
| Fisher | Fish 插件 | `private_dot_config/private_fish/fish_plugins.tmpl` |
| chezmoi 脚本 | 平台配置、服务和软件包编排 | `.chezmoiscripts/` |

如果工具已经在上述配置源中声明，不要手动安装；应该修改声明，然后重新 apply。

## Herdr 与 Collie

Herdr 本体的版本固定在 Aqua 配置中。Herdr 插件声明在
`.chezmoidata/herdr.yaml` 中，并由编号的 Herdr 脚本同步。
定时版本工作流会更新稳定版插件 ref 并创建 PR，但不会自动在机器上安装更新。

Collie 当前在 `office-server` profile 中配置为直接通过局域网访问。
它的主机地址只保存在本机，Git 跟踪的模板只引用 `{{ .collieHost }}`。
启动或重启服务前，使用 `chezmoi diff` 检查生成的 `.env`。

## 加密与私有数据

没有配置密钥时，age 加密文件应当无法读取。
不要为了通过检查而将加密文件替换成明文，也不要提交 API 密钥、应保持私密的 IP 地址或生成的服务状态。
迁移背景请参阅 `docs/migrate-from-nix.md`；恢复指南会独立于已应用的 dotfiles 维护。

## 自动化

- `.github/workflows/update-versions.yml` 更新固定版本并创建依赖更新 PR。
- `.github/workflows/update-aqua-packages.yml` 更新 Aqua registry 和软件包版本。
- `.github/workflows/scheduler.yml` 触发定时更新工作流。
- `.github/workflows/ci.yml` 在 Pull Request 和推送到 `main` 时验证模板、渲染后的 shell 脚本和仓库机密信息。

## 安全原则

这是一个声明式配置仓库，不是无人值守的部署流水线。
应用改动前请先检查 `chezmoi diff`，提交或推送前必须获得操作者的明确授权。
