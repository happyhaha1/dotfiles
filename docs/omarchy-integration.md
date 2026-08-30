# 在 Omarchy 上复用本 dotfiles 仓库 — 调研与集成方案

> 调研日期：2026-08-30 · Omarchy 最新稳定版 v4.0.1（2026-08-25 发布）
> 权威手册：<https://omarchy.org/manual/dotfiles/>（v4 · lua 覆盖文件体系）。
> 注意：learn.omacom.io 上的手册仍是旧一代（.conf 体系），内容已过时。
> 结论先行：**完全可行，且现有仓库的 feature-flag 架构天然支持**。核心工作是把
> 「平台维度」从隐式（全 macOS）升级为显式（darwin / linux + omarchy flag），
> 并为 Omarchy 补一套 pacman/AUR 包管理脚本。

---

## 1. Omarchy 现状调研

### 1.1 两代架构（决定配置文件路径，务必先确认机器版本）

| | v2.x / v3.x（旧一代） | v4.0 "Quattro"（当前稳定版） |
| --- | --- | --- |
| 系统文件位置 | `~/.local/share/omarchy`（git checkout，`omarchy update` 时 `git pull`） | `/usr/share/omarchy`（pacman 包 `omarchy`，更新整包替换） |
| 用户配置位置 | `~/.config`（安装时从 `default/` 复制） | `~/.config`（覆盖层，加载顺序：默认值 → 你的覆盖文件） |
| Hyprland 配置 | `hyprland.conf` + `monitors.conf` 等一系列 `.conf` | `hyprland.lua` + `bindings.lua` / `monitors.lua` / `input.lua` / `looknfeel.lua` / `autostart.lua`（`.lua` 覆盖文件） |
| 官方手册 | learn.omacom.io（已过时） | omarchy.org/manual/dotfiles/ |
| 默认终端 | alacritty（foot/ghostty 也随附） | foot |
| AUR 包装 | `yay` | `omarchy-pkg-add <pkg>` 封装 |
| 扩展机制 | 手工 | hooks（`~/.config/omarchy/hooks/<event>.d/`）、菜单扩展、shell 插件 |
| 查看版本 | `omarchy version` | `omarchy version` |

**检查命令**：`omarchy version`。仓库改造需要同时兼容两者（文件名 `.conf` vs `.lua`
用模板条件切换，或按机器实际版本只管理其中一套）。

### 1.2 官方边界哲学（chezmoi 共存的根基）

- `~/.config` **是你的** —— 官方手册明确"considered your files for your changes"，
  推荐 Stow/版本管理，chezmoi 管理这里名正言顺。
- `/usr/share/omarchy`（v4）或 `~/.local/share/omarchy`（v3）**是 Omarchy 的** ——
  不要管理、不要改；要改行为就在 `~/.config` 覆盖。
- 改坏了可 `omarchy reinstall configs` 一键重置 `~/.config` —— 重置后
  `chezmoi apply` 即可恢复你的版本，互为备份。

### 1.3 更新机制对 chezmoi 的影响

- `omarchy update` = pacman 事务 + 迁移脚本（migrations）+ post-update hooks。
- **迁移脚本可能改动 `~/.config` 下的文件**（比如新增默认键位文件）。这是唯一
  系统性的漂移源。chezmoi 的 `diff`/`apply` 会把漂移拉回，但注意：
  - 迁移若是「追加式」（如新建文件），chezmoi 源里没有它 → apply 会**删掉**它
    （如果所在目录是 `exact_`）。**Linux 侧的 hypr/waybar 目录不要用 `exact_` 前缀**。
  - 迁移若是「改写式」（改了你管理的文件），apply 会覆盖迁移成果 —— 通常正是
    你想要的，但升级后值得 `chezmoi diff` 过目一遍。
- `sudo pacman -Syu` 被 ALPM hook 拦截，必须走 `omarchy update` —— 所以
  chezmoi 的 Linux 包安装脚本**只能装包，不要做系统升级**。

### 1.4 值得利用的官方扩展点

- **hooks**：`~/.config/omarchy/hooks/post-update.d/` 放一个 `chezmoi apply`，
  让 Omarchy 迁移跑完后自动恢复你的覆盖 —— 完美闭环。
- **`~/.config/omarchy/packages.txt`**（社区惯例）：记录非 Omarchy 默认的用户包，
  可由 chezmoi 管理并作为安装脚本的数据源。
- v4 的 `shell.json` 陷阱：一旦改过 bar 布局，你的副本就是全部事实，不再跟随
  官方默认更新。要么不进 dotfiles，要么接受手工跟版。

---

## 2. 现有仓库可移植性盘点

### 2.1 直接跨平台复用（无需改动或小改）

| 组件 | 说明 |
| --- | --- |
| `.chezmoi.toml.tmpl` | 已有 work/private、headless、useEncryption 等 flag；`osid`/`platform` 已入库，加 Linux 分支即可 |
| age 加密（`~/.ssh/main` 身份） | age 支持以 SSH key 为身份；Linux 上 `pacman -S age` 后现有 wrapper 的 `command -v age` 兜底直接工作 |
| aqua（`.chezmoidata` + 脚本） | aqua 原生支持 linux/amd64、arm64；个别工具需加平台过滤 |
| mise | 原生跨平台，无需改动 |
| fisher + fish 配置 | fish 配置已用 `type -q`/`test -d` 防御；仅 `brew --prefix` 补全路径和 openssl 段需加 `type -q brew` 守卫或平台条件 |
| git / nvim / bat / delta / lazygit / yazi / zellij / atuin / fzf / direnv / gh / gh-dash / starship | 纯跨平台 CLI，直接复用 |
| ghostty | Linux 上可用（Omarchy 也随附）；`macos-*` 键需模板化（Linux 会忽略但有告警） |
| `.ssh/`、opencode、pi | 加密 SSH 配置与 agent 工具链跨平台 |

### 2.2 macOS 专属（Linux 上必须 ignore）

aerospace、raycast、karabiner（如入库）、borders、hammerspoon、cmux、herdr、
surge、omnyssh、`.Brewfile`、macOS defaults 脚本、`installMasApps` /
`homeWifiSSIDs` / `isMacbook` 相关逻辑。

### 2.3 Omarchy 新增面（仓库目前没有）

`~/.config/hypr/`（覆盖层）、`~/.config/waybar/`、`~/.config/walker/`、
`~/.config/foot|ghostty/`、`~/.config/omarchy/`（packages.txt、hooks、主题）、
`~/.XCompose`、pacman/AUR 包清单与安装脚本。

---

## 3. 集成方案

### 3.1 配置维度：加一个 `omarchy` flag（最小侵入）

`.chezmoi.toml.tmpl` 在现有 flag 体系上追加：

```gotemplate
{{- $omarchy := false -}}
{{- if and (eq .chezmoi.os "linux") (stdinIsATTY) -}}
{{-   $omarchy = promptBoolOnce . "omarchy" "Is this an Omarchy (Hyprland) machine" -}}
{{- end -}}
...
omarchy = {{ $omarchy }}
```

本地 `~/.config/chezmoi/chezmoi.toml` 固化答案，二次 init 不再询问。

### 3.2 `.chezmoiignore`：按平台分流（核心开关）

```gotemplate
{{- if ne .chezmoi.os "darwin" }}
# macOS 专属：一切 Apple 生态
.Brewfile
.config/aerospace/
.config/raycast/
.config/karabiner/
.config/borders/
.config/hammerspoon/
.config/cmux/
.config/herdr/
.config/surge/
.config/omnyssh/
{{- end }}

{{- if ne .chezmoi.os "linux" }}
# Linux 专属：Wayland/Hyprland 栈
.config/hypr/
.config/waybar/
.config/walker/
.config/foot/
.config/omarchy/
.XCompose
{{- end }}
```

> 注意现有 `headless` 段落会把 aerospace 等按 headless 排除 —— 与 OS 维度
> 正交，保留即可。

### 3.3 包管理：三轨并行

| 平台 | 机制 | 仓库内形态 |
| --- | --- | --- |
| macOS GUI/字体/ MAS | Homebrew（现状不动） | `private_Brewfile.tmpl` + `run_onchange_after_02` |
| Omarchy GUI/AUR | pacman 显式清单 + `paru`/`omarchy-pkg-add` | `.chezmoidata/pacman.yaml`（shared/work/private 分组，与 homebrew.yaml 同构）+ `run_onchange_after_02_pacman.sh.tmpl` |
| CLI 工具 | aqua + mise + fisher（现状不动，天然双平台） | 不变 |

`pacman.yaml` 示例：

```yaml
pacman:
  official:   # pacman -S --needed
    shared: [fish, ghostty, age, direnv, wl-clipboard, ...]
    work: []
    private: []
  aur:        # paru -S --needed
    shared: [bitwarden, ...]
```

脚本只做 `--needed` 增量安装，**绝不 `-Syu`**（Omarchy guard 会拦截，也应拦截）。

### 3.4 Hyprland/Waybar：只管理「覆盖层」

- **v4**：仅入库 `hypr/bindings.lua`、`monitors.lua`（按 hostname 模板）、
  `input.lua`、`looknfeel.lua`、`autostart.lua`、`omarchy/shell.json`（慎重）、
  `omarchy/hooks/post-update.d/chezmoi-apply`。
- **v3**：对应 `.conf` 文件。`monitors.conf` 一律 hostname 模板（参考社区
  marckrieger/dotfiles 的做法）。
- 目录**不加** `exact_` 前缀，避免 chezmoi 删除 Omarchy 迁移新建的文件。

### 3.5 跨平台组件的收尾改造

- `config.fish`：brew 段加 `type -q brew` 守卫（或 `switch (uname)`），Linux 上
  `fish_add_path ~/.local/share/omarchy/bin`（v3）/ 无需（v4）。
- `ghostty/config`：`macos-*` 三行包进 `{{ if eq .chezmoi.os "darwin" }}`。
- age wrapper：现兜底已够；可在 Linux 分支提示 `sudo pacman -S --needed age`。
- `.chezmoi-bootstrap-macos.sh`：改名或复制一份 Linux 版（`read-source-state`
  hook 按平台选择；Linux 版只需保证 `age`、`git` 存在 —— Omarchy 自带 git）。
- 时区探测：`readlink /etc/localtime` 在 systemd Linux 同样成立，把 darwin
  条件放宽到 `or (eq .chezmoi.os "linux")`。

### 3.6 Omarchy 机器首次接入流程

```bash
# 0. 前置（Omarchy 自带 git；fish/age 由步骤 2 装）
omarchy version   # 确认 v3 还是 v4，决定管理哪套文件名

# 1. 建立本地配置（固化答案，免交互）
chezmoi init --apply <你的repo>   # 按提示回答 flag
# 或先 chezmoi init <repo> 再手写 ~/.config/chezmoi/chezmoi.toml

# 2. chsh -s fish && chezmoi apply   # 包脚本装 fish/ghostty/age 等

# 3. 验证
chezmoi diff          # 应为空或只剩 omarchy 迁移漂移
chezmoi doctor
```

### 3.7 日常双机工作流

```bash
# 任一台改完
chezmoi edit ~/.config/...   # 或直接改源仓库
chezmoi cd && git add -A && git commit -m "..." && git push

# 另一台
just update                  # chezmoi update
omarchy update               # Omarchy 自己的更新（hooks 里已挂 chezmoi apply）
```

---

## 4. 风险与对策

| 风险 | 对策 |
| --- | --- |
| Omarchy 迁移改写 `~/.config` 与 chezmoi 打架 | post-update hook 自动 `chezmoi apply`；升级后人工 `chezmoi diff` 复核 |
| `exact_` 目录误删迁移新增文件 | Linux 侧 hypr/waybar/omarchy 目录不用 `exact_` |
| v3/v4 文件名不同（.conf/.lua） | 用 `omarchy` flag + 版本探测分流，或只管理机器实际版本 |
| 直接 `pacman -Syu` 绕过 Omarchy 更新管线 | chezmoi 脚本只 `--needed` 装包，升级永远走 `omarchy update` |
| `omarchy reinstall configs` 清掉覆盖文件 | chezmoi 源就是备份，apply 即恢复 |
| shell.json 一旦拥有就不再跟随官方默认 | 要么不管理，要么升级时对照 `omarchy bar defaults` 手工跟版 |
| aqua 个别工具无 Linux 包 | aqua.yaml 中按 `os: [linux/darwin]` 过滤；缺的进 pacman 清单 |

## 5. 备选方案对比（为何不选）

- **GNU Stow**：无模板/加密/脚本编排，双平台差异全靠手工拆目录，弱于现状。
- **Nix home-manager**：声明式最强，但本仓库刚从 Nix 迁出（见
  `docs/migrate-from-nix.md`），且 Omarchy 社区主流是 chezmoi/Stow，生态不匹配。
- **Homebrew on Linux**：与 Arch 包体系冲突、瓶装支持差、和 omarchy update 的
  pacman guard 哲学相悖，明确不采用。

---

## 6. 实施记录（2026-08-30，目标 v4 已确认）

已完成的仓库改造：

| 文件 | 变更 |
| --- | --- |
| `.chezmoi.toml.tmpl` | 新增 `omarchy` 自动检测（`/usr/share/omarchy` 存在即 true）；时区探测放宽到 Linux |
| `.chezmoiignore` | 按 OS 分流：Linux 跳过 Brewfile/aerospace/raycast/cmux/surge；macOS 跳过 hypr/omarchy |
| `.chezmoidata/pacman.yaml` | 新增：fish、age、ghostty、bitwarden（private）；AUR 清单留空待用 |
| `.chezmoiscripts/run_onchange_after_02_pacman.sh.tmpl` | 新增：优先 `omarchy-pkg-add`，备选裸 pacman，仅 `--needed`，绝不 `-Syu` |
| `.chezmoiscripts/run_onchange_before_01_ensure-age.sh.tmpl` | age 安装增加 pacman 分支 |
| `.chezmoitemplates/shell/age_command_wrapper.sh` | 同上（读源状态时兜底） |
| `private_dot_config/ghostty/config.tmpl` | `macos-*` 三键模板化，Linux 渲染时省略（由 `config` 重命名） |
| `private_dot_config/private_fish/config.fish` | brew 补全路径段加 `type -q brew` 守卫 |
| `private_dot_config/hypr/bindings.lua` | 新增：官方注释版起始覆盖文件 |
| `private_dot_config/omarchy/hooks/post-update.d/executable_chezmoi-apply` | 新增：`omarchy update` 迁移后自动 `chezmoi apply` |

Mac 侧验证：`chezmoi diff` 仅含脚本伪条目，无目标文件变化。

## 7. Omarchy 机器接入步骤（v4）

```bash
# 0. 前置（交互式，fish/age 也顺便装上）
sudo pacman -S --needed git fish age

# 1. 拉 repo 并初始化（会提示 hostname / email 等，omarchy flag 自动检测）
chezmoi init --apply <你的repo>   # 若未装 chezmoi: omarchy-pkg-add chezmoi
# 或者：pacman 里装： sudo pacman -S --needed chezmoi

# 2. 把 bash 换成 fish（可选但推荐，复用整套 fish 配置）
chsh -s fish

# 3. 把机器上已有的个性化覆盖导入版本库（monitors/input/looknfeel/shell.json）
chezmoi add ~/.config/hypr/monitors.lua   # 机器专属，务必先 add 再 apply
chezmoi add ~/.config/hypr/input.lua      # 若改过
chezmoi add ~/.config/omarchy/shell.json  # 若定制过 bar（注意跟版成本）
chezmoi cd && git add -A && git commit -m "omarchy: import machine overrides" && git push

# 4. 验证
chezmoi diff        # 应为空
omarchy update      # 观察末尾 post-update hook 自动跑 chezmoi apply
```

> 注意：步骤 1 的 `--apply` 会用仓库起始文件覆盖 `bindings.lua`（纯注释版，
> 无损）；但**不要**在导入 `monitors.lua` 之前盲目 apply——若机器上已有
> 个性化 monitors.lua，先执行步骤 3 的 `chezmoi add` 再 apply。

### 日常双机工作流

- 任一台改动：`chezmoi edit` → `just cm "..."` → `just push`
- 另一台同步：`just update`（macOS）/ `omarchy update && chezmoi update`（Omarchy）
- Omarchy 大版本升级后：跑一次 `chezmoi diff` 看迁移是否碰了托管文件
