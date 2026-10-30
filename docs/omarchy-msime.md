# Omarchy: 水杉输入法（MSIME）

Omarchy 上只声明一个 Fcitx5 中文输入法：水杉（MSIME）。Rime 已于 2026-10-29
下架，包声明与受管配置均已移除，配置存档在 `docs/backup/rime/`（不安装）。

## 归属

| 关注点 | 位置 |
| --- | --- |
| 包 | `.chezmoidata/omarchy.yaml` → `omarchyAurPackages.shared: msime-bin` |
| 输入法列表与默认 IM | `private_dot_config/fcitx5/private_profile.tmpl`（模板） |
| 默认 IM 取值 | `.chezmoidata/omarchy.yaml` → `omarchyInputMethod.defaultIM` |
| 首次配置 / 词库 / 服务重启 | `.chezmoiscripts/run_onchange_after_12_omarchy-packages.sh.tmpl` |
| Omarchy 主题钩子 | `private_dot_config/omarchy/hooks/theme-set.d/symlink_msime` |
| 状态栏组件 | 不纳管（见下文「状态栏组件不可用」） |

## 为什么必须用 `--no-register`

AUR 包 `msime-bin` 是上游 Debian `data.tar` 的原样重打包，**不执行** Debian 的
`postinst`/`prerm`。上游的自动注册逻辑因此不会跑，必须显式调用
`msime-linux-setup`。

同时 `msime-linux-setup` 默认会自己往 `~/.config/fcitx5/profile` 写「水杉输入法」。
那个文件由 chezmoi 声明式管理，两边都写会互相覆盖，所以脚本固定加
`--no-register`，让 chezmoi 独占 `profile`，并只做词库与运行状态准备。

## 首次配置

`chezmoi apply` 时 `after_12` 会：

1. 通过 `omarchy pkg aur add` 安装 `msime-bin`；
2. 若 `~/.config/msime-client` 不存在，跑 `msime-linux-setup --download --no-register`
   （首次约 170 MB 词库）；已存在则跑 `--update --download --no-register`；
3. 重启 `omarchy-fcitx5.service` 并等待 D-Bus 名字，然后按 `defaultIM` 选中输入法。

词库下载失败只打印警告，不会让 `chezmoi apply` 失败。离线机器可把
`omarchyInputMethod.msime.downloadDictionaries` 设为 `false`，再手动准备词库。

## 切换与默认值

- 运行时切换：`Ctrl+Space` 在 `keyboard-us` → `msime` 之间循环，
  `Ctrl+Shift+Space` 反向。
- **不要用 `Super+Space`**：它被 Omarchy 绑成了主菜单（`hyprctl binds` 里
  modmask 8 + SPACE = Omarchy menu），Fcitx5 收不到这个键。
- **`EnumerateForwardKeys` 必须写成列表段**：

  ```ini
  [Hotkey/EnumerateForwardKeys]
  0=Control+space
  ```

  行内形式 `EnumerateForwardKeys=Control+space` 会被 Fcitx5 静默忽略
  （它和 `TriggerKeys` 一样是 KeyList，不是标量），这也是最初“绑了键却切不动”
  的直接原因。
- 改默认：`omarchyInputMethod.defaultIM` 目前只有 `msime` 一个可选值；新增输入法时
  同步改这里、`private_profile.tmpl` 的 Items 和 `after_12` 里的 `case` 分支即可。
- 中英切换：`private_config` 里刻意没有把 `Ctrl+Space` 绑给 `TriggerKeys`，
  `AltTriggerKeys` 留空。MSIME 的模式切换键在 `msime-linux-settings` 里查看。
- Fcitx5 退出时会把当前输入法写回 `profile` 的 `DefaultIM`。若 `chezmoi apply`
  提示 `.config/fcitx5/profile` 已被修改，那是这个运行时写回，确认覆盖即可
  （或先切回 `defaultIM` 再 apply）。

## 隐私

`msime-bin` 的 `optdepends` 里 `python-websockets` 控制云端候选与在线 provider。
不安装该依赖即可物理关闭这些联网功能；本地引擎与本地词频学习不受影响。
语音（`pipewire`）与状态栏组件（`quickshell`）同样按需启用。

## 状态栏组件不可用

`msime-linux-setup` 会把上游的水杉 bar widget 以**符号链接**形式放进
`~/.config/omarchy/plugins/metasequoia.msime`。实测 Omarchy 的插件注册表
（`omarchy plugin list --json`）不会发现符号链接的插件目录，所以：

- 不把它写进 `omarchyPlugins`：`local: true` 要求 `run_after_21` 能在列表里
  找到它，而它永远不会被找到，apply 会直接报错；
- 也不把它留给 `pruneUnmanaged`：那会让每次 apply 多一条删除日志。

因此 `run_onchange_after_12` 在跑完 setup 后主动删掉这个链接。输入功能不受影响，
只是没有状态栏上的「中/英」小部件；需要看当前模式时用输入法自己的候选窗提示。

## 卸载

`omarchy pkg drop` 不会执行 Debian `prerm`，因此顺序必须是：

```bash
msime-linux-setup --unregister    # 清输入法列表与主题钩子链接
# 再从 .chezmoidata/omarchy.yaml 删除 msime-bin 与 omarchyInputMethod.msime，然后：
chezmoi apply                     # after_12 会 omarchy pkg drop msime-bin
rm -rf ~/.config/msime-client ~/.local/share/msime-client
```

如果先删声明、后跑 `--unregister`，`after_12` 会在状态目录仍存在时打印一行提示，
提醒先反注册再删除。

## 验证

```bash
fcitx5-remote -n                 # 期望 msime
chezmoi diff                     # 期望为空：setup 不再改写 profile
just doctor
```

首次 apply 后确认上游安装路径与仓库里的符号链接目标一致（上游把 Omarchy
集成文件装在 `/usr/share/msime-client/omarchy/`）：

```bash
pacman -Ql msime-bin | grep 'omarchy/'
ls -l ~/.config/omarchy/hooks/theme-set.d/msime
```

若上游改了目录名，主题钩子会变成悬空链接；此时只需改
`private_dot_config/omarchy/hooks/theme-set.d/symlink_msime` 里的目标路径。
