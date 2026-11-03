# Pi 与 omp 的 `agent` 配置为什么用 `modify_` 脚本

`~/.omp/agent/config.yml` 由 omp 在运行时自己改写：它会重新序列化整份 YAML。
因此这个文件不能当作普通副本（plain copy）交给 chezmoi 管理。

## 问题

omp 的写法有三个和 chezmoi 冲突的特征：

1. **丢弃注释**：每次保存都用 YAML 序列化器重写整份文件，源文件里的注释不会保留。
2. **追加自己的键**：例如 `dev.autoqaConsent`、`browser.headless` 这类随版本或交互
   产生的开关和迁移字段，由 omp 直接写进同一份文件。
3. **不写结尾换行**：omp 的输出末尾没有 `\n`，而编辑器与大多数 YAML 工具会补上。

chezmoi 判断目标“是否被外部改动”用的是**整份内容的 SHA-256**，逐字节比对。
所以只要源文件产不出 omp 的字节序列，每次 `chezmoi apply` 都会询问：

```text
.omp/agent/config.yml has changed since chezmoi last wrote it?
[diff,overwrite,all-overwrite,skip,quit]?
```

拒绝一次只会让下次继续弹；接受 `overwrite` 又会把 omp 刚写下的键冲掉。
plain copy 无法收敛，因为源文件与 omp 的输出永远不可能逐字节相同。

## 方案

源文件是 `private_dot_omp/private_agent/modify_private_config.yml` ——
chezmoi 的 [`modify_` 脚本](https://www.chezmoi.io/user-guide/manage-different-types-of-file/#manage-part-but-not-all-of-a-file)：

- stdin 收到目标文件的当前内容（不存在时为空）；
- stdout 的内容就是 chezmoi 认为目标应当具有的内容。

脚本只声明本仓库拥有的键，并用格式保留的 `yq` 就地修改，其余内容原样透传。
chezmoi 对 `modify_` 目标记录的是**脚本**而不是内容哈希，所以 omp 自己写入的
键不再算作外部改动，提示消失。

### 脚本拥有的键

| 键 | 值 |
| --- | --- |
| `symbolPreset` | `nerd` |
| `composer.shape` | `band` |
| `theme.dark` / `theme.light` | `titanium` / `light` |
| `setupVersion` | `2` |
| `task.agentModelOverrides.security-reviewer` | `@slow` |
| `extensions` | 追加 OpenViking、Graphify 固定目录及 Pi 管理的 Billion Context 的 `omp-native.js`（去重） |
| `compaction.enabled` | `false` |
| `memory.backend` | `"off"` |

`extensions` 用“追加并去重”而不是整体赋值，避免覆盖 omp 之后加入的扩展。

OpenViking 与 Graphify 由编号 20 的 `run_onchange_after_20_agent-extensions.sh.tmpl`
安装到固定目录，Pi 自动发现同一份扩展。Billion Context 由 Pi 的
`npm:billion-context` 声明安装，omp 共享加载
`~/.pi/agent/npm/node_modules/billion-context/dist/agent/omp-native.js`；
首次启动 omp 前必须先完成 Pi 包安装，更新后两端均需重启。
包括 Graphify 在内的技能及其跨工具链接统一由 Magpie 管理，dotfiles 不再安装技能或维护技能链接。

### 模型、provider 与思考强度

以下内容不属于本仓库，由 Magpie 写入，脚本原样保留：

- `defaultThinkingLevel` 与 `modelRoles.*` 中除 `designer` 外的角色（`default`、
  `plan`、`task`、`advisor`、`smol`、`slow`、`tiny`、`commit`、`vision` 等）；
- `~/.omp/agent/models.yml` 中的 provider 定义：Magpie 的适配器写入 `magpie`
  provider，默认指向 Magpie 自己托管的网关；
- Pi 侧 `~/.pi/agent/models.json` 的 provider 定义，以及 `~/.pi/agent/settings.json`
  的 `defaultProvider`、`defaultModel`、`enabledModels`、`defaultThinkingLevel`。

Magpie 的官方适配器把 provider 写进 Pi 的 `models.json` 和 omp 的 `models.yml`，
同时写入对应的模型设置与 `enabledModels`；会话思考强度通过 `defaultThinkingLevel`
设置，omp 各角色还可使用模型引用末尾的 `:level`。dotfiles 不再声明这些键的基线值。

两个例外由 dotfiles 断言，因为它们跟随的不是某个具体模型，或者 Magpie 不接管：

- `modelRoles.designer`：`magpie omp` 的字段表（`model`、`subagent`、`small`、
  `slow`、`plan`、`vision`、`advisor`、`commit`、`tiny`、`memory`、`effort`）
  没有 `designer`，Magpie 不会改写它，只有仓库能保证它指向
  `magpie/remote-magpie/group/designer:high`；
- `task.agentModelOverrides.security-reviewer: "@slow"`：跟随的是 Magpie 的
  `slow` 角色，而不是某个具体模型。

Magpie 自动接线默认使用本机网关；此前由 dotfiles 写死的 `home-magpie` 远程网关
不会自动迁移。启用 Magpie、导入凭据、创建模型组由使用者在 Magpie 中完成，
chezmoi 不执行这些操作。现有 `MAGPIE_API_KEY` 的 fish secret 导出不在这里删除；
Magpie 不会自动导入环境变量中的 key，凭据仍需在 Magpie 内单独添加。

模型组（例如 `group/memory`）必须先在 Magpie 中存在。SoL-Pi 的 reducer 在
`private_dot_pi/agent/private_sol-pi.json` 中指向 `magpie` provider 的
`group/memory`；该组缺失或凭据未配置时，Pi 端的证据压缩请求会失败。

### 不属于脚本的内容

- `defaultThinkingLevel`、`modelRoles.*` 中除 `designer` 外的角色、`dev.*`、
  `browser.*` 以及任何 omp 后续新增的键，一律原样保留。
- 注释：omp 自己不会保留，所以这里也不再声明；`compaction` 与 `memory` 的语义
  改由本文档说明。这两个键关闭 omp 内建压缩与记忆，让 Billion Context 管理上下文；
  已安装的 Magic Context 需执行 `omp plugin disable @cortexkit/pi-magic-context` 停用。
  OpenViking 保持 `takeoverEnabled: false`，长期记忆由 OpenViking 提供。

## 行为

| 情况 | 结果 |
| --- | --- |
| 目标不存在（首次 apply、CI 渲染） | 写出上面的完整基线（含 `modelRoles.designer`，不含其他模型路由与思考强度） |
| omp 追加自己的键、或去掉结尾换行 | `chezmoi status` 干净，apply 不重写文件（字节一致） |
| omp 改动了我们拥有的键 | `chezmoi status` 报 `MM`，apply 恢复我们的值并保留 omp 的键 |
| 目标 YAML 损坏 | `yq` 报错，apply 非零退出，目标不被改写（fail-closed） |
| `yq` 不存在（极早的 bootstrap） | 原样透传并在 stderr 提示，下次 apply 再收敛 |
| 结尾换行 | 保留输入的状态：输入没有就不补，已有就保留 |

## Pi 的 `agent/settings.json`

`~/.pi/agent/settings.json` 同样会被 Pi 在运行时改写，因此改用
`private_dot_pi/agent/modify_settings.json.tmpl` 这个 `modify_` 脚本管理，
不再使用整份模板或 plain copy。脚本结构与 omp 版本一致：`mktemp` 接收当前内容、
`find_yq` 回退查找 `yq`、保留输入的结尾换行状态。

脚本只断言本仓库拥有的 UI、工具与包声明：

| 键 | 值 |
| --- | --- |
| `lastChangelogVersion` | `99.99.99` |
| `theme` | Omarchy 上 `omarchy-system`，macOS 上 `dracula` |
| `defaultTools` | `["+codemode"]` |
| `packages` | dracula 主题、Billion Context、powerbar、goal、web-access、extmgr 与 SoL-Pi |

`defaultProvider`、`defaultModel`、`enabledModels`、`defaultThinkingLevel`
以及 Pi 后续新增的未知字段都原样保留，由 Magpie 写入。

- `~/.pi/agent/models.json` 不再有仓库源文件，provider 定义由 Magpie 适配器写入。
- `~/.pi/agent/auth.json` 仍由 age 加密源 `encrypted_private_auth.json.age` 管理，
  本次不改变其管理方式；Magpie 不写这个文件。
- `~/.pi/agent/web-search.json` 仍是 `symlink_web-search.json` 指向
  `../web-search.json` 的符号链接，内容来自加密源，本次不变。
- `yq` 缺失时脚本原样透传并在 stderr 提示，与 omp 脚本行为一致。

## 依赖与检查

- `yq` 固定在 `private_dot_config/aquaproj-aqua/aqua.yaml`（`mikefarah/yq`）。
  脚本先查 `PATH`，再回退到 `${AQUA_ROOT_DIR:-$XDG_DATA_HOME/aquaproj-aqua}/bin/yq`
  和 `~/.local/bin/yq`。
- `.github/workflows/ci.yml` 的 ShellCheck 步骤会对 omp 与 Pi 的两个
  `modify_` 脚本执行 `shellcheck --severity=warning`。
- 改动此脚本后，本地验证：

  ```bash
  shellcheck --severity=warning private_dot_omp/private_agent/modify_private_config.yml
  shellcheck --severity=warning private_dot_pi/agent/modify_settings.json.tmpl
  chezmoi diff
  chezmoi status
  ```