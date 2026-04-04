# PROJECT KNOWLEDGE BASE

**生成时间：** 2026-04-01
**Commit：** a0205d3
**Branch：** main

## 概览

这是一个以 chezmoi 为核心的个人环境仓库，混合管理模板化 dotfiles、Nix 配置、Neovim 配置，以及 OpenCode 技能与命令。根目录负责跨子系统的约束；具体实现细节下沉到 `nix-config/`、`private_dot_config/nvim/`、`private_dot_config/opencode/`。

## 结构

```text
./
├── .chezmoi.toml.tmpl        # chezmoi 入口模板，负责首次提示与全局数据装配
├── .chezmoidata/             # 模板输入数据，版本与包列表来源
├── .chezmoiscripts/          # chezmoi 生命周期脚本
├── .github/workflows/        # 定时更新与 PR 自动化
├── Justfile.tmpl             # 本地维护命令入口
├── nix-config/               # Nix flakes 与模块
└── private_dot_config/       # 最终映射到 ~/.config 的各类配置
```

## 到哪里改

| 任务 | 位置 | 说明 |
|---|---|---|
| 调整初始化提问、平台变量 | `.chezmoi.toml.tmpl` | 根入口，影响模板渲染和交互式初始化 |
| 更新统一数据源 | `.chezmoidata/*.yaml` | 版本、包清单、平台参数都从这里注入 |
| 增加本地维护命令 | `Justfile.tmpl` | `chezmoi`、`nix`、`git`、系统更新都从这里进入 |
| 增加 apply 钩子或安装逻辑 | `.chezmoiscripts/` | 命名本身表达执行时机，优先复用现有阶段 |
| 调整 CI 定时任务 | `.github/workflows/` | 当前主要负责 flake、versions、aqua 更新 |
| 改系统/Nix | `nix-config/` | 先读子目录 AGENTS |
| 改 Neovim | `private_dot_config/nvim/` | 先读子目录 AGENTS |
| 改 OpenCode 配置或技能容器 | `private_dot_config/opencode/` | 先读子目录 AGENTS |

## 仓库约定

- 这是 **chezmoi 源仓库**，不是目标目录；提交的是源文件、模板和数据，不是渲染结果。
- `.tmpl` 文件优先保持模板语义，避免把平台分支、交互提示改成静态值。
- 敏感文件用 chezmoi 加密文件保存，仓库里已有 `.age` 模式；普通明文密钥不应进入 Git。
- `.chezmoidata/` 是共享数据源；如果多个模板都依赖同一信息，优先抽到这里，而不是各自硬编码。
- `Justfile.tmpl` 是人工维护入口，`.github/workflows/` 是自动化入口；两边的命令语义应保持一致。

## 本仓库反模式

- 不要把 `.chezmoiignore` 中明确忽略的内容当作 chezmoi 管理对象，例如 `.github/`、`node_modules/`、部分锁文件和 GUI 目录。
- 不要提交 `*.key`、`*.pem`、`*.local.*`、日志、缓存、`result*` 这类本地或敏感产物。
- 不要在根文档里重复子系统内部规则；根文件只写跨目录不变量。
- 不要把生成物或上游样板当作主要维护对象，例如 fish 的自动生成 completion、超长注释型配置。

## 常用命令

```bash
just apply
just diff
just check
just fmt
just update-all
```

## 备注

- `.chezmoi.toml.tmpl` 会根据平台、是否 headless、是否启用加密动态裁剪最终文件集合。
- `.github/workflows/scheduler.yml` 每天触发多个更新工作流，仓库默认存在自动 PR 流。
- 修改子系统前，优先读对应子目录的 `AGENTS.md`；如果该目录还有 `SKILL.md`，再继续下钻读取。
