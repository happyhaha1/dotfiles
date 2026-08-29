# 从 Nix / nix-darwin 迁移到新版 dotfiles

本文记录本仓库从 Nix / nix-darwin 迁移到 **chezmoi + Homebrew + Aqua + mise + Fisher** 的流程。

> 当前仓库目标是 macOS。Linux 的 Nix 配置已移除，不要把本文流程用于 Linux 主机。

## 1. 迁移后的职责

| 组件 | 职责 |
| --- | --- |
| chezmoi + age | 配置文件、模板和加密文件 |
| Homebrew | macOS 软件、服务、GUI、字体以及 `age`、Fish |
| Aqua | 固定版本的独立 CLI 二进制 |
| mise | Node.js、Python、Go、Rust、Java 等运行时和工具 |
| Fisher | Fish 插件 |
| direnv | 项目环境变量 |
| Nix | 不再使用 |

Nix 中的 macOS defaults、主机名、时区、电源和 Touch ID sudo 设置，已经迁移到：

```text
.chezmoiscripts/run_onchange_after_03_macos-settings.sh.tmpl
```

## 2. 新电脑：只准备 chezmoi

### 前置条件

1. macOS、网络和可用的 sudo 权限。
2. 在交互式终端中运行 `chezmoi init --apply`。Homebrew 官方安装器需要交互式终端。
3. 如果仓库中的加密文件需要应用，必须通过安全方式准备：

   ```text
   ~/.ssh/main
   ~/.ssh/main.pub
   ```

   软件可以自动安装，但 age 私钥不能由 dotfiles 自动生成或恢复。

### 初始化命令

安装好 `chezmoi` 后直接执行：

```bash
chezmoi init --apply <repository-url>
```

`.chezmoi.toml.tmpl` 中的 `hooks.read-source-state.pre` 会在读取加密 source state 之前调用：

```text
.chezmoi-bootstrap-macos.sh
```

启动链路如下：

```text
chezmoi
  └─ read-source-state.pre
       ├─ 检测官方 Homebrew
       ├─ Homebrew 不存在 → 执行官方安装器
       ├─ age 不存在 → brew install age
       └─ 读取并解密 source state
            └─ chezmoi apply
                 ├─ Homebrew Bundle
                 ├─ macOS settings
                 ├─ Aqua
                 ├─ mise
                 └─ Fisher
```

后续 apply 会根据以下清单安装软件：

```text
.chezmoidata/homebrew.yaml
private_dot_config/aquaproj-aqua/aqua.yaml
private_dot_config/mise/config.toml.tmpl
.chezmoidata/fisher.yaml
```

### 已有但非官方的 Homebrew

bootstrap 脚本不会覆盖已有的非官方 Homebrew。例如检测到：

```text
/opt/homebrew/bin/brew -> /nix/store/...
```

脚本会停止并要求先恢复官方 Homebrew。这是为了避免新机器或旧机器上的自动流程静默破坏已有环境。

## 3. 已有 Nix 机器的迁移

### 3.1 先备份 Homebrew 清单

如果当前 `brew` 仍然可以运行：

```bash
HOMEBREW_NO_AUTO_UPDATE=1 \
  brew bundle dump --file=/tmp/Brewfile.current --force
```

这个文件只记录当前 Homebrew 可见的软件，不包含 Nix profile 中的包。

### 3.2 备份 Nix 配置

不要备份整个 `/nix` store，只需备份配置和安装收据：

```bash
backup="/tmp/nix-pre-uninstall-$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup"
cp -a "$HOME/nix-config" "$backup/" 2>/dev/null || true
cp -a "$HOME/.config/nix" "$backup/" 2>/dev/null || true
cp -a /nix/receipt.json "$backup/" 2>/dev/null || true
sudo cp -a /Library/LaunchDaemons/org.nixos.*.plist "$backup/" 2>/dev/null || true
sudo cp -a /Library/LaunchDaemons/systems.determinate.*.plist "$backup/" 2>/dev/null || true
printf 'backup: %s\n' "$backup"
```

保留备份，直到迁移和验证全部完成。

### 3.3 恢复官方 Homebrew

先确认 Homebrew 是否由 Nix 管理：

```bash
readlink /opt/homebrew/bin/brew
/opt/homebrew/bin/brew --repository
```

如果路径指向 `/nix/store`，只移动 wrapper 和旧 Homebrew 目录，不要移动软件数据：

```text
/opt/homebrew/Cellar
/opt/homebrew/Caskroom
/opt/homebrew/var
/opt/homebrew/etc
```

创建备份目录：

```bash
backup="/tmp/homebrew-legacy-$(date +%Y%m%d%H%M%S)"
sudo mkdir -p "$backup"
```

将存在的旧路径移动到备份目录：

```bash
sudo mv /opt/homebrew/bin/brew "$backup/opt-homebrew-bin-brew"
sudo mv /opt/homebrew/Library/Homebrew "$backup/opt-homebrew-Library-Homebrew"
sudo mv /opt/homebrew/.managed_by_nix_darwin "$backup/opt-homebrew-managed-marker"
sudo mv /opt/homebrew/Library/.homebrew-is-managed-by-nix "$backup/opt-homebrew-library-marker"
sudo mv /usr/local/bin/brew "$backup/usr-local-bin-brew"
sudo mv /usr/local/Homebrew "$backup/usr-local-Homebrew"
```

只移动实际存在的路径；不存在的路径可以跳过。

然后安装官方 Homebrew：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

确认：

```bash
command -v brew
brew --repository
brew doctor
```

期望：

```text
/opt/homebrew/bin/brew
/opt/homebrew
Your system is ready to brew.
```

### 3.4 先确保 age

```bash
brew install age
```

这是必要的，因为 chezmoi 读取加密 source state 早于普通 `run_before` 脚本。

然后应用新版 dotfiles：

```bash
chezmoi diff
chezmoi apply
```

### 3.5 先卸载 nix-darwin，再卸载 Nix

直接执行 Nix installer 会得到：

```text
nix-darwin installation detected, it must be removed first
```

正确顺序：

```bash
sudo /run/current-system/sw/bin/darwin-uninstaller
```

看到提示后输入 `y`。如果本地命令不存在，可以使用官方替代命令：

```bash
sudo nix --extra-experimental-features "nix-command flakes" \
  run nix-darwin#darwin-uninstaller
```

nix-darwin 卸载完成后，再执行：

```bash
sudo /nix/nix-installer uninstall
```

不要手动执行：

```bash
rm -rf /nix
```

Nix 在 macOS 上通常使用 APFS 存储卷，应由 installer 负责卸载。

### 3.6 清理卸载残留

确认 LaunchDaemon 已清理：

```bash
launchctl list | grep -Ei 'nix|determinate' || echo clean
```

确认没有系统级 Nix 路径：

```bash
for path in \
  /run/current-system \
  /nix/nix-installer \
  /usr/local/bin/determinate-nixd \
  /etc/profile.d/nix.sh; do
  test -e "$path" || test -L "$path" && echo "still exists: $path"
done
```

确认无误后，删除用户级旧目标：

```bash
rm -rf \
  "$HOME/nix-config" \
  "$HOME/.config/nix" \
  "$HOME/.nix-profile" \
  "$HOME/.nix-defexpr" \
  "$HOME/.cache/nix" \
  "$HOME/.local/state/nix"
```

最后清理卸载残留配置：

```bash
sudo rm -rf /etc/nix
```

在现代 macOS 中，根目录位于 sealed、read-only 的系统卷。卸载后暂时看到空的 `/nix` 是正常现象；直接执行 `sudo rmdir /nix` 会得到：

```text
Read-only file system
```

不要强制删除它。nix-darwin 卸载器会移除 `/etc/synthetic.conf` 中的 `nix` 配置；重启一次后，macOS 会自动移除这个 synthetic mountpoint：

```bash
sudo reboot
```

重启后验证：

```bash
test ! -e /nix && echo '/nix cleanup complete'
```

如果 `/etc/synthetic.conf` 仍然存在，只删除其中独立的 `nix` 行，不要删除其他 synthetic entries：

```bash
sudo sed -i '' '/^nix$/d' /etc/synthetic.conf
```

## 4. 包迁移对照

| 原 Nix 内容 | 新位置 | 说明 |
| --- | --- | --- |
| `age` | Homebrew | 解密 source state 的启动依赖 |
| Fish | Homebrew | login shell 使用 `/opt/homebrew/opt/fish/bin/fish` |
| CMake、chezmoi、FFmpeg、Neovim、ouch、resvg | Aqua | 使用独立发布的 macOS ARM64 二进制 |
| Node、pnpm、Bun、Python、uv、Poetry、Go、Rust、Java | mise | 见 mise 配置 |
| GUI、服务、字体 | Homebrew | 见 Homebrew 数据清单 |
| macOS defaults | chezmoi script | 不再依赖 nix-darwin |
| `mihomo`、`nix-index`、`statix`、`nixfmt` | 删除 | 当前工作流没有使用 |
| `wget`、`zstd` | Homebrew bottle | Aqua 没有合适的 macOS ARM64 包 |

Homebrew 默认优先下载预编译 bottle，不会默认编译源码。检查当前安装来源：

```bash
brew info --json=v2 wget zstd
```

如果不需要 `wget`，可以使用 macOS 自带的：

```bash
/usr/bin/curl
```

## 5. 迁移后的验证

重新打开终端后执行：

```bash
command -v brew age fish chezmoi aqua mise nvim cmake ffmpeg ouch resvg
brew doctor
```

这些路径应分别来自：

```text
/opt/homebrew/bin
/opt/homebrew/opt/fish/bin
~/.local/share/aquaproj-aqua/bin
```

检查当前 shell 是否还残留旧 Nix PATH：

```bash
printf '%s\n' "$PATH" | tr ':' '\n' |
  grep -E '/(nix|current-system|\.nix-profile)' ||
  echo 'Nix PATH clean'
```

现有终端可能继承旧环境，必要时执行：

```bash
exec fish -l
```

## 6. 日常更新

迁移后不再运行 `darwin-rebuild` 或更新 Nix flake。常用命令：

```bash
just bundle       # Homebrew Bundle
just aqua-install # Aqua 固定版本 CLI
aqua install
just mise-install
mise install
just update-all
```

Homebrew 没有 Nix flake 的精确回滚能力，因此重要变更前应保留：

```bash
brew bundle dump --file=/tmp/Brewfile.current --force
```
