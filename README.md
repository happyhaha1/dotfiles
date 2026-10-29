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
- `office-server`：办公室/服务器 profile；Roamgate 与 Herdr Web UI 局域网集成在此 profile 启用。
- `other`：非交互式或无法分类机器的安全默认 profile。

Roamgate 的局域网地址等机器私有数据保存在本机 chezmoi 配置中（使用 `chezmoi edit-config` 设置），
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

脚本文件名中的数字就是 apply 日志里 `:: [NN]` 的步骤编号：`before` 阶段是
`[01]`–`[02]`，随后 `after` 阶段按编号升序执行，全部 25 个脚本编号连续且唯一。
同一阶段里 `run_onchange_` 与 `run_after_` 的文件名属性会被剥离后排序，
因此两类脚本共用同一条编号序列。Herdr 入口 `[10]` 下的 Pi 集成、插件、
Web UI 和 Roamgate 阶段使用不带编号的缩进行。
重命名会改变 `run_onchange_` 脚本的状态键，修改日志也会改变渲染内容；
受影响的脚本会在下一次 apply 时重跑一次，安装和服务逻辑保持不变。

如果工具已经在上述配置源中声明，不要手动安装；应该修改声明，然后重新 apply。

## Pi 用户扩展包更新

Pi 由 mise 固定管理 npm 包 `@earendil-works/pi-coding-agent`，macOS 与 Omarchy
共用 `~/.local/bin/pi`，使用 mise 管理的 Node 执行 npm 官方入口。
版本声明在 `private_dot_config/mise/config.toml.tmpl`。
Pi 的用户级扩展包声明在 `private_dot_pi/agent/settings.json.tmpl` 的 `packages` 中。
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
生成 Pi 的 `~/.pi/agent/skills/graphify/`，并复制该版本自带的 Guard 到固定扩展目录，
避免 mise 清理旧虚拟环境后扩展路径失效。omp 的同名技能链接到 Pi 技能目录。
无需另行执行 `pi install`、`omp plugin install` 或安装 MCP；Guard 保持默认提示模式。
每个项目自行运行 `graphify extract . --code-only` 建图，修改后用 `graphify update .`
刷新；dotfiles 不自动扫描项目或安装项目 Git hooks。
版本变化会触发编号 20 的 `run_onchange`；仅删除生成文件不会触发，修复时需显式
重跑该脚本。更新后重启 Pi/omp 加载新版扩展。
Magic Context 的加密配置与历史数据库保留，但不再由 Pi 加载或由升级流程更新。
omp 上已有的 Magic Context 必须手动禁用，避免与 Billion Context 同时管理上下文。
新插件不会导入旧的 Magic Context 会话档案，旧会话的原文检索仍需要原插件。

### omp 的 `agent/config.yml`

`~/.omp/agent/config.yml` 由 omp 在运行时自行重写（重排 YAML、丢弃注释、追加
`dev.*` 等自有键、不写结尾换行），因此不能用普通副本管理：每次 apply 都会判定为
外部改动并提示 `has changed since chezmoi last wrote it?`。

该文件改由 `private_dot_omp/private_agent/modify_private_config.yml` 这个
chezmoi `modify_` 脚本管理：脚本用格式保留的 `yq` 只声明本仓库拥有的键，
其余内容原样透传，omp 自己写入的键不再产生 diff。
详细设计与拥有的键清单见 `docs/omp-agent-config.md`。

## Herdr、Roamgate 与 Web UI

Herdr 本体的版本固定在 Aqua 配置中。Herdr 插件声明在
`.chezmoidata/herdr.yaml` 中，由统一入口
`.chezmoiscripts/run_after_10_herdr.sh.tmpl` 按顺序同步 Pi 集成、插件、Web UI 和 Roamgate。
入口在每次完整 apply 时执行；插件已经对齐时不会重复安装。
各阶段使用子 shell 隔离变量、退出和清理 trap，失败会中止后续阶段。
定时版本工作流会更新稳定版插件 ref 并创建 PR，但不会自动在机器上安装更新。

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

Roamgate 当前在 `office-server` profile 中配置为直接通过局域网访问，使用 `8788` 端口。
它的主机地址只保存在本机，Git 跟踪的模板只引用 `{{ .roamgateHost }}`。
Roamgate 密码只保存在本机 chezmoi 配置中：

```bash
chezmoi edit-config
```

在 `[data]` 下设置 `roamgatePassword`；不要将真实密码写入 Git 跟踪文件。
启动或重启服务前，使用 `chezmoi diff` 检查生成的配置；包含密码的 diff 不要上传或分享。

### Roamgate 服务同步

统一的 `[10]` 入口更新插件文件、同步 Web UI 后，最后检查 Roamgate 服务。
版本/配置变化、后台停止或实际版本仍旧时，使用官方 `start` 动作刷新服务定义并重启，
不重启 Herdr 主进程或 Web UI。`restart` 只重启已有定义，不能刷新旧二进制路径。
正常且未变化的服务不会重启；首次启用同步时会刷新一次。
macOS 的 `bootout` 是异步卸载：刷新前只卸载已验证的 Roamgate job，按原生状态轮询
等待它完全消失（等待预算 20 秒），再次核对定义后才执行官方 `start`。不存在的 job
直接启动；卸载失败、检查异常或超时则中止，不盲目重试 `bootstrap` 或使用固定延时。
Linux 继续使用官方的 systemd 服务同步，不额外停止服务。

同步只作用于 dotfiles 拥有且已启用、source/ref 匹配的插件。自动同步要求已配置
固定 `roamgatePassword`，env 权限为 `0600`；模板对密码的 shell 特殊字符作字面转义，
不会执行其中的 `$`、反引号或命令替换。只有官方生成且未手改的 launchd/systemd 定义
（路径指向当前或上次已验证的插件 binary）可被刷新；自定义定义、symlink 或 systemd
覆盖项（包括尚未 daemon-reload 的磁盘覆盖项）会报错并保留原服务；检测到旧 Herdr GUI
服务定义时也不会自动强制迁移。自定义 HTTPS 配置不由此 HTTP 同步器接管。

脚本等待 Herdr 动作日志成功，再用密码登录并核对后台 `/api/health` 的 `version`
与 manifest 一致、`auth_required=true` 且未登录访问返回 `401`；`/healthz` 或插件的
`version` 动作不足以证明正在运行的版本。成功后原子写入本机私有状态戳
`~/.local/state/chezmoi/roamgate`（遵循 `XDG_STATE_HOME`），只含 ref、配置哈希和 binary
路径，不含密码。动作失败、超时或版本/鉴权不匹配时保留旧状态戳并报错，不标记同步成功。

### Herdr Web UI

Herdr Web UI 同样仅在 `office-server` profile 启用。插件安装仍由
`.chezmoidata/herdr.yaml` 和统一的 `[10]` 入口管理；插件同步后，Web UI 阶段
检查私有状态戳和健康状态，版本/配置变化或服务停止时等待 `stop` 完成后
执行 `start`，不重启 Herdr 主进程或 Roamgate。未变化的健康服务不会重启，
未纳入 dotfiles 所有权或被禁用的插件不会被接管。从 manifest/profile 移除已管理的
Web UI 时，`[10]` 会先等待它停止，再卸载插件，避免留下后台服务。

上游已把仓库 `devswha/herdr-web-ui` 改名为 `devswha/ovis`（显示名 Ovis），
plugin id 仍是 `devswha.herdr-web-ui`，`.env` 路径、`HERDR_WEB_*` 变量和
`start`/`stop` 动作都未变。Herdr 按安装时请求的仓库名记录来源，因此在改名
之前安装过的机器仍报旧名：`[10]` 把两个名字视为同一个插件，保留已安装的来源
而不是卸载重建，manifest 则统一写 `devswha/ovis`。

私有模板生成 `~/.config/herdr/plugins/config/devswha.herdr-web-ui/.env`（权限 `0600`）：

- `HOST` 复用本机 `[data].roamgateHost`，端口为 `7317`，不与 Roamgate 的 `8788` 冲突。
- `HERDR_WEB_TOKEN` 按操作者选择复用 `[data].roamgatePassword`；网页要求 token 时输入同一个密码。
  更换该密码会同时影响两个服务；完整 apply 时统一的 `[10]` 入口依次同步 Web UI 与 Roamgate。
- 不另设密钥、不提交真实 IP/密码；缺少 host/password 或含换行时拒绝渲染/安装。
- 只管理 `.env`；旧 `env` 同名配置被 `.env` 覆盖，不要维护两份冲突的配置。
- Node/Bun 继续由 mise 管理，`~/.local/bin` shim 解决 Herdr 后台 PATH 不含 mise 的问题。

应用前执行 `chezmoi diff`，再执行 `chezmoi apply`。服务脚本等待 Herdr 动作日志
成功结束，并验证健康响应、无 token 返回 `401`、使用 token 可访问，再写入本机状态戳。
安全状态戳不含明文密码。启动或鉴权验证失败时尝试停止该插件的服务并报错，不标记同步成功。
首次完整应用会安装/启动 Web UI，不需要再手动安装插件。

`update-versions.yml` 将 Web UI 的正式 `vX.Y.Z` app ref 纳入版本 PR，排除 `remote-vN`
远程运行时包。`HERDR_WEB_AUTO_UPDATE=0` 禁止内置自动安装，但网页的手动 Update
仍能绕过 pin：**不要在网页更新 Web UI/Herdr，统一走版本 PR 和 chezmoi/Aqua 应用。**
远程 PC 连接、设备配对及下载缓存由应用管理，不纳入 Git；此接入不会修改远端机器、
Tailscale 或防火墙。普通 HTTP 只用于受信任网络，手机 PWA/推送仍需要 HTTPS。

集成与服务同步的无副作用回归测试：
`node --test docs/tests/herdr-integrations.test.mjs docs/tests/herdr-web-ui.test.mjs docs/tests/roamgate.test.mjs`。

## 加密与私有数据

没有配置密钥时，age 加密文件应当无法读取。
不要为了通过检查而将加密文件替换成明文，也不要提交 API 密钥、应保持私密的 IP 地址或生成的服务状态。
迁移背景请参阅 `docs/migrate-from-nix.md`；恢复指南会独立于已应用的 dotfiles 维护。

## 自动化

- `.github/workflows/update-versions.yml` 更新固定版本并创建依赖更新 PR。
- `.github/workflows/update-aqua-packages.yml` 更新 Aqua registry 和软件包版本。
- `.github/workflows/scheduler.yml` 触发定时更新工作流。
- `.github/workflows/ci.yml` 在 Pull Request 和推送到 `main` 时验证模板、渲染后的 shell 脚本和仓库机密信息。

两个更新工作流使用 Create PR 步骤的 `pull-request-number` output 启用 squash auto-merge；所需 CI 检查通过后由 GitHub 自动合并。

## 安全原则

这是一个声明式配置仓库，不是无人值守的部署流水线。
应用改动前请先检查 `chezmoi diff`，提交或推送前必须获得操作者的明确授权。
