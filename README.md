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

## Atuin 智能体会话

`private_dot_config/atuin/config.toml` 在 macOS 和 Omarchy 上启用 Threads 会话及工具调用捕获，
并由 Atuin 自动启动 daemon；会话沿用现有 `sync_address` 和同步账号进行端到端加密同步。
Atuin 版本由 Aqua 管理，通过 `Update aqua packages` workflow 更新。

配置应用后，运行 `atuin threads list` 检查捕获，运行 `atuin resume` 搜索并恢复会话。
Fish 中按 `Ctrl+]` 打开 Threads 搜索，普通模式和 vi 插入模式均可使用。
已有但未继续使用的会话需要手动运行 `atuin threads import` 导入；dotfiles 不自动批量导入。
跨机器恢复前，目标机器需登录同一同步服务器并配置相同加密密钥，同时准备好项目文件和依赖。

## 机器 Profile

持久化的 chezmoi 数据会选择模板和安装脚本使用的 profile：

- `daily`：普通的交互式 Mac profile。
- `home-server`：减少桌面配置的 macOS 服务器 profile。
- `office-server`：办公室/服务器 profile；EasyTier 服务器节点等服务器侧配置在此启用。
- `other`：非交互式或无法分类机器的安全默认 profile。

## 软件包归属

按照依赖类型使用对应的软件包管理器：

| 管理器 | 负责内容 | 配置来源 |
| --- | --- | --- |
| Homebrew | macOS formula、cask、字体和 App Store 应用 | `.chezmoidata/homebrew.yaml` |
| Aqua | 固定版本的可移植 CLI 二进制文件 | `private_dot_config/aquaproj-aqua/aqua.yaml` |
| mise | 语言运行时和选定的运行时工具 | `private_dot_config/mise/config.toml.tmpl` |
| Fisher | Fish 插件 | `private_dot_config/private_fish/fish_plugins.tmpl` |
| chezmoi 脚本 | 平台配置、服务和软件包编排 | `.chezmoiscripts/` |

脚本文件名中的数字就是 apply 日志里 `:: [NN]` 的步骤编号：`before` 阶段是
`[01]`–`[02]`，随后 `after` 阶段按编号升序执行，全部 25 个脚本编号连续且唯一。
同一阶段里 `run_onchange_` 与 `run_after_` 的文件名属性会被剥离后排序，
因此两类脚本共用同一条编号序列。Herdr 入口 `[10]` 下的 Pi 集成与插件阶段
使用不带编号的缩进行。
重命名会改变 `run_onchange_` 脚本的状态键，修改日志也会改变渲染内容；
受影响的脚本会在下一次 apply 时重跑一次，安装逻辑保持不变。

如果工具已经在上述配置源中声明，不要手动安装；应该修改声明，然后重新 apply。

Omarchy 状态栏布局由 `private_dot_config/omarchy/shell.json` 管理，使用
`centerBegin`、`center`、`centerEnd` 分别声明中间区域的左侧、居中组件和右侧。
通知铃铛 `jankeesvw.notification-center` 固定在 `right` 数组末尾，位于 `omarchy.power` 之后。
插件同步脚本只在组件不在声明区域时移动它，区域内的顺序由 `shell.json` 决定，
避免每次 apply 重新排序并导致下一次 apply 提示冲突。
Omarchy 升级迁移或设置界面也会改写本机 `~/.config/omarchy/shell.json`；
出现 `has changed since chezmoi last wrote it` 时，先核对差异，将要保留的布局和
插件设置同步回源文件，再仅应用该文件，避免覆盖当前配置。

## Pi 用户扩展包更新

Pi 由 mise 固定管理 npm 包 `@earendil-works/pi-coding-agent`，macOS 与 Omarchy
共用 `~/.local/bin/pi`，使用 mise 管理的 Node 执行 npm 官方入口。
版本声明在 `private_dot_config/mise/config.toml.tmpl`。
`just full-upgrade` 使用 `mise upgrade --minimum-release-age 0s` 升级所有 mise 工具，
统一跳过新版本的发布冷却期；macOS 与 Omarchy 使用相同策略。
Pi 的用户级扩展包声明在 `private_dot_pi/agent/modify_settings.json.tmpl` 的
`packages` 中；该 `modify_` 脚本只断言主题、默认工具、扩展包和 changelog 版本，
provider、默认模型、`enabledModels` 与思考强度由 Magpie 写入并原样保留。
`just pi-extensions-update` 通过共享脚本执行 `pi update --extensions --no-approve`：
仅更新用户扩展，不更新 mise 管理的 Pi，不加载项目包配置或重载运行中的会话。
脚本通过 mise 定位 Pi 与 Node；缺少 agent 目录、用户 settings 或 Pi payload 时跳过，
解析和更新失败会报错。`PI_CODING_AGENT_DIR` 可覆盖 agent 目录。

`just update-all` 和 `just full-upgrade` 在 mise 之后调用同一个脚本；
`just aqua-install` 与完整 apply 的 `[10]` 入口都不更新扩展包，apply 保持无副作用。
Herdr 生成的 `~/.pi/agent/extensions/herdr-agent-state.ts` 不属于这些包，
仍由 `herdr integration install pi` 对齐。

Billion Context 由 Pi 的 `npm:billion-context` 包声明安装到
`~/.pi/agent/npm/node_modules/billion-context`：Pi 使用包声明的 `pi-native.js`，
omp 的 `extensions` 显式加载同一份包的 `dist/agent/omp-native.js`。
无需 mise 安装 Billion Context，也无需运行 `bili plugin install omp`；
chezmoi 负责声明 omp 的入口，Pi 扩展更新流程负责升级共享包。
`~/.config/billion-context/billion-context.json` 关闭自更新和 advisory 更新，
避免绕过 Pi 的包管理。当前使用默认的模型主动压缩，不配置独立摘要模型或 `autoFold`。

首次切换时先 apply 配置，再执行 `just pi-extensions-update` 安装新包，
然后执行 `omp plugin disable @cortexkit/pi-magic-context` 停用已安装的旧插件。
新机器没有安装 Magic Context 时不需要这一步；已有插件与历史数据库保留。
完成安装后重启 Pi 和 omp，再用 `/acp` 验证两端加载；不要在共享包尚未安装时启动 omp。
更新共享包前退出 Pi/omp，更新后重启；运行中的会话不会自动加载新代码。
检查压缩、原文恢复和 OpenViking 召回是否正常。omp 原生模式的部分 Anthropic Cowork
请求会绕过代理，使用该传输时还需验证实际请求是否受到压缩。

回归测试：`node --test docs/tests/pi-extensions-update.test.mjs`。

OpenViking 与 Graphify 由
`.chezmoiscripts/run_onchange_after_20_agent-extensions.sh.tmpl` 统一安装到
`~/.pi/agent/extensions/`，不属于上述 `packages` 更新范围。
Pi 自动发现扩展；omp 通过 `~/.omp/agent/config.yml` 显式加载同一份目录。
版本声明在 `.chezmoidata/versions.yaml`，定时版本 workflow 检查上游稳定 release，
通过版本更新 PR 更新 OpenViking 扩展 commit 和 Graphify 版本；机器在后续 apply 时安装。
OpenViking CLI 仍由 mise 单独跟踪 latest，服务端版本不由此脚本修改。
OpenViking 保持 `takeoverEnabled: false`，长期记忆由 OpenViking 提供，上下文管理由 Billion Context 负责。

Graphify CLI 由 mise 的 `pipx:graphifyy` 安装，使用同一个版本声明；编号 20 脚本
复制该版本自带的 Guard 到固定扩展目录，避免 mise 清理旧虚拟环境后扩展路径失效。
所有 agent 技能及其跨工具链接统一由 Magpie 管理，dotfiles 不再下载、安装、链接或更新技能。
无需另行执行 `pi install`、`omp plugin install` 或安装 MCP；Guard 保持默认提示模式。
每个项目自行运行 `graphify extract . --code-only` 建图，修改后用 `graphify update .`
刷新；dotfiles 不自动扫描项目或安装项目 Git hooks。
版本变化会触发编号 20 的 `run_onchange`；仅删除生成文件不会触发，修复时需显式
重跑该脚本。更新后重启 Pi/omp 加载新版扩展。
Magic Context 的加密配置与历史数据库保留，但不再由 Pi 加载或由升级流程更新。
omp 上已有的 Magic Context 必须手动禁用，避免与 Billion Context 同时管理上下文。
新插件不会导入旧的 Magic Context 会话档案，旧会话的原文检索仍需要原插件。

### Pi 与 omp 的配置归属

`~/.pi/agent/settings.json` 与 `~/.omp/agent/config.yml` 都由各自程序在运行时改写，
plain copy 每次 apply 都会判定为外部改动并提示
`has changed since chezmoi last wrote it?`。两者因此改由 chezmoi `modify_` 脚本管理：

| 文件 | 脚本 | 脚本拥有的内容 |
| --- | --- | --- |
| `~/.pi/agent/settings.json` | `private_dot_pi/agent/modify_settings.json.tmpl` | `theme`、`lastChangelogVersion`、`defaultTools`、`packages` |
| `~/.omp/agent/config.yml` | `private_dot_omp/private_agent/modify_private_config.yml` | UI、扩展、`task.agentModelOverrides.security-reviewer`、`compaction`、`memory` |

脚本用格式保留的 `yq` 只声明本仓库拥有的键，其余内容原样透传；`yq` 尚未由 aqua
安装时原样透传并在 stderr 提示，下次 apply 再收敛。

provider 定义、模型角色、默认模型、`enabledModels` 与思考强度统一由 Magpie 管理：
Magpie 把 `magpie` provider 写入 `~/.pi/agent/models.json` 与 `~/.omp/agent/models.yml`，
并把选择写回两个 agent 的配置；dotfiles 不再提供这两个 models 文件，也不再声明
`modelRoles` 或 `defaultThinkingLevel`。唯一例外是 `modelRoles.designer`：`magpie omp`
没有这个字段，不会被 Magpie 改写，因此由 `modify_` 脚本固定为
`magpie/remote-magpie/group/designer:high`。Magpie 自动接线默认指向本机网关，原先的
`home-magpie` 远程网关不会自动迁移；启用 Magpie、导入凭据和创建模型组是独立步骤，
本次改动不执行 apply，且 Magpie 不会自动导入 `MAGPIE_API_KEY`；该 secret 导出仍
保留给其他程序使用，凭据需在 Magpie 内单独添加。

`~/.pi/agent/auth.json` 仍由加密源 `encrypted_private_auth.json.age` 管理，Magpie
不写它；`~/.pi/agent/web-search.json` 仍是指向 `../web-search.json` 的符号链接。
SoL-Pi 的 reducer 使用 `magpie` provider 的 `remote-magpie/group/memory`，直接引用
已接入的远端 memory 组，无需本机转发组；远端组缺失或凭据未配置时，Pi 端的证据压缩请求会失败。

详细设计与拥有的键清单见 `docs/omp-agent-config.md`。

## Herdr 插件管理

Herdr 本体的版本固定在 Aqua 配置中。Herdr 插件声明在
`.chezmoidata/herdr.yaml` 中，目前只有两个插件，对所有 profile 一致：

- `senna-lang/herdr-agent-usage`：usagebar。
- `thanhdat77/herdr-navigator`：herdr-navigator。

统一入口 `.chezmoiscripts/run_after_10_herdr.sh.tmpl` 在每次完整 apply 时按顺序
同步 Pi 集成和插件；插件已经对齐时不会重复安装，失败会中止后续阶段。
定时版本工作流会更新这两个插件的稳定版 ref 并创建 PR，但不会自动在机器上安装更新。

### Herdr 官方 Pi 集成

`[10]` 的 Pi 集成阶段在 Aqua 安装步骤后调用共享脚本
`~/.local/bin/herdr-integrations-sync`。该脚本执行当前 Aqua 管理的 Herdr 的官方
`integration install pi`，让集成随 CLI 更新，不另行固定集成版本，也不将生成的
`~/.pi/agent/extensions/herdr-agent-state.ts` 纳入 chezmoi 文件管理。
重复执行会对齐集成；生成文件被删除后，下次 apply 也会补回。
同步器独立设置 Aqua 配置上下文，用 `aqua which` 确认真实的已安装可执行文件；
拒绝 PATH 回退并禁用懒安装，不因残留代理而误装软件。

`just aqua-install`、`just update-all` 和 `just full-upgrade` 在 Aqua 安装成功后
也调用同一个脚本。缺少 Aqua 管理的 Herdr 或 Pi agent 目录时明确跳过；
官方安装器失败会报错并中止对应配方，不被 `|| true` 吞掉。
脚本遵循 `AQUA_ROOT_DIR`、`XDG_DATA_HOME` 和 Pi 的 `PI_CODING_AGENT_DIR`。
直接手动运行 Aqua 安装/更新不触发 dotfiles 脚本，之后可手动调用共享脚本。

此同步只更新磁盘上的集成文件，不重启 Herdr 或 Pi；已运行的 Pi 需要
`/reload` 或下次启动才加载新集成。它不会让 Pi 二进制本身升级。

### 插件同步与归属

统一入口只安装 manifest 中声明的插件。所有权状态戳
`~/.local/state/chezmoi/herdr-plugins`（遵循 `XDG_STATE_HOME`）只记录 dotfiles
安装过的 source 与 ref：已记录且 ref 未变时跳过，ref 变化时原位升级，从 manifest
移除时卸载。从未被记录的插件属于使用者，dotfiles 不接管、不替换也不卸载；
全部安装与卸载成功后才写入状态戳。

卸载只针对状态戳中记录的、dotfiles 曾经拥有的插件注册，通用同步不停止任何后台服务。
旧配置在既有机器上留下的独立服务，需要先用该服务自己的官方 `stop`/卸载动作停止并移除，
再从 manifest 删除对应插件；只删除 manifest 条目不会停止这些守护进程。

manifest 会拒绝空 source、重复 source 和含换行符的 source/ref。缺少 Herdr 时跳过
插件同步并提示下次 apply 重试，因此未安装 Herdr 的机器仍可完整 apply。

集成与插件同步的无副作用回归测试：
`node --test docs/tests/herdr-integrations.test.mjs`。

## 加密与私有数据

没有配置密钥时，age 加密文件应当无法读取。
不要为了通过检查而将加密文件替换成明文，也不要提交 API 密钥、应保持私密的 IP 地址或生成的服务状态。
迁移背景请参阅 `docs/migrate-from-nix.md`；恢复指南会独立于已应用的 dotfiles 维护。

## 自动化

- `.github/workflows/update-versions.yml` 更新固定版本并创建依赖更新 PR。
  OpenViking 从完整发布列表中筛选非草稿、非预发布的 `vX.Y.Z` 或 `vX.Y.Z.W` 主程序标签，按发布时间选择最新版本，避免将同仓库中的 SDK、CLI 或 LangChain 集成包 Release 误作主程序版本；仍保留空值和版本格式校验。
- `.github/workflows/update-aqua-packages.yml` 更新 Aqua registry 和软件包版本。
- `.github/workflows/scheduler.yml` 触发定时更新工作流。
- `.github/workflows/ci.yml` 在 Pull Request 和推送到 `main` 时验证模板、渲染后的 shell 脚本和仓库机密信息。

两个更新工作流使用 Create PR 步骤的 `pull-request-number` output 启用 squash auto-merge；所需 CI 检查通过后由 GitHub 自动合并。

## 安全原则

这是一个声明式配置仓库，不是无人值守的部署流水线。
应用改动前请先检查 `chezmoi diff`，提交或推送前必须获得操作者的明确授权。
