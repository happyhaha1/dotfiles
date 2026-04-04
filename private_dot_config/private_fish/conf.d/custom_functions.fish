# 使用 AI 自动生成并提交 git commit
# 用法: aicommit [prompt]
# 示例: aicommit "修复登录 bug"
function aicommit
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Not a git repository"
        return 1
    end

    if test (count $argv) -eq 0
        set prompt "帮我提交下代码"
    else
        set prompt $argv
    end

    opencode run "$prompt"
end

# 创建目录并进入，目录不存在时自动创建（包括多级目录）
# 用法: mkcd <目录路径>
# 示例: mkcd foo/bar/baz
function mkcd
    mkdir -p $argv[1]; and cd $argv[1]; or return 1
end

# mkcd 的别名，take 是 zsh 用户熟悉的习惯命名
# 用法: take <目录路径>
function take
    mkcd $argv
end

# ─────────────────────────────────────────────────────────────
# Direnv Helper Functions
# ─────────────────────────────────────────────────────────────

# 创建 Python venv 的 direnv 环境
# 用法: create_direnv_venv
function create_direnv_venv
    echo 'layout uv' >.envrc
    direnv allow
end

# 创建 Nix flake 的 direnv 环境
# 用法: create_direnv_nix
function create_direnv_nix
    echo 'use flake' >.envrc
    direnv allow
end

# 创建 mise 的 direnv 环境
# 用法: create_direnv_mise
function create_direnv_mise
    echo 'use mise' >.envrc
    direnv allow
end

# ─────────────────────────────────────────────────────────────
# Project Creation
# ─────────────────────────────────────────────────────────────

# 使用 uv 快速创建 Python 项目
# 用法: create_py_project [name]
function create_py_project
    set name (test (count $argv) -gt 0; and echo $argv[1]; or echo ".")

    if test "$name" != "."
        mkdir -p "$name" && cd "$name" || return 1
    end

    uv init
    create_direnv_venv
    echo "Python project created!"
end

# ─────────────────────────────────────────────────────────────
# System Utilities
# ─────────────────────────────────────────────────────────────

# 在 Finder（或默认文件管理器）中打开路径
# 用法: o [path]
function o
    open (test (count $argv) -gt 0; and echo $argv[1]; or echo ".")
end

# 查看占用指定端口的进程
# 用法: port <port_number>
function port
    if test (count $argv) -eq 0
        echo "Usage: port <port_number>"
        return 1
    end
    lsof -i ":$argv[1]"
end

# 复制 stdin 到剪贴板（跨平台）
# 用法: echo "text" | clip
function clip
    if test (uname) = Darwin
        pbcopy
    else
        xclip -selection clipboard
    end
end

# ─────────────────────────────────────────────────────────────
# Quick Edit
# ─────────────────────────────────────────────────────────────

# 在编辑器中打开 dotfiles
# 用法: dotfiles
function dotfiles
    set editor (set -q EDITOR; and echo $EDITOR; or echo nvim)
    $editor (chezmoi source-path)
end