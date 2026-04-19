# FZF-powered shell functions

# ─────────────────────────────────────────────────────────────
# ghq + fzf Integration
# ─────────────────────────────────────────────────────────────

# 交互式仓库选择器，基于 ghq + fzf
# 用法: dev [query]
# 功能:
#   - 模糊搜索所有 ghq 管理的仓库
#   - 预览: eza 目录树 + README + git 分支
#   - 自动重命名 tmux session
#   - Ctrl+O: 在 VS Code 中打开
#   - Ctrl+E: 在编辑器中打开
#   - Ctrl+Y: 复制路径到剪贴板
function dev
    set ghq_root (ghq root)
    set editor (set -q EDITOR; and echo $EDITOR; or echo nvim)

    set repo (
        ghq list | fzf \
            --query=(test (count $argv) -gt 0; and echo $argv[1]; or echo "") \
            --preview "
            set repo_path $ghq_root/{}
            echo -e '\033[1;34m📁 {}\033[0m'
            echo ''
            if test -d \$repo_path/.git
                set branch (git -C \$repo_path branch --show-current 2>/dev/null)
                echo -e '\033[1;33m⎇ \$branch\033[0m'
                echo ''
            end
            eza --tree --level=2 --color=always --icons --git-ignore \$repo_path 2>/dev/null
            echo ''
            for readme in \$repo_path/README \$repo_path/README.md \$repo_path/README.rst \$repo_path/README.txt \$repo_path/readme \$repo_path/readme.md
                if test -f \$readme
                    echo -e '\033[1;32m📖 README\033[0m'
                    bat --color=always --style=plain --line-range=:20 \$readme 2>/dev/null
                    break
                end
            end
            " \
            --preview-window='right:55%:border-left:wrap' \
            --header='Enter: cd | Ctrl+O: VS Code | Ctrl+E: Editor | Ctrl+Y: copy path' \
            --bind="ctrl-o:execute-silent(code $ghq_root/{})" \
            --bind="ctrl-e:execute($editor $ghq_root/{})" \
            --bind="ctrl-y:execute-silent(echo $ghq_root/{} | pbcopy)+abort"
    )

    if test -n "$repo"
        cd $ghq_root/$repo; or return 1
        if test -n "$TMUX"
            tmux rename-session (string split -r -m1 / "$repo")[-1]
        end
    end
end

function _ghq_fzf_cd
    set repo (
        ghq list | fzf \ --height=40% \
            --reverse \
            --preview 'eza --tree --level=1 --color=always --icons "(ghq root)/{}"' \
            --preview-window='right:40%:border-left'
    )
    if test -n "$repo"
        cd (ghq root)/$repo
        commandline -f repaint
    end
end

bind \cg _ghq_fzf_cd

# ghq 包装器：无参数时用 fzf 选择仓库，有参数时正常执行 ghq
function ghq
    if test (count $argv) -eq 0
        dev
    else
        command ghq $argv
    end
end

# 用 fzf 选择分支并切换，支持预览提交历史
# 用法: fgc
function fgc
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Not a git repository"
        return 1
    end

    set branch (
        git branch -a --color=always \
        | grep -v '/HEAD' \
        | fzf --ansi --preview 'git log --oneline --graph --color=always {1}' \
        | string trim \
        | string replace -r '^\*\s*' '' \
        | string replace 'remotes/origin/' ''
    )

    if test -z "$branch"
        return 0
    end

    git checkout "$branch"
end



# ─────────────────────────────────────────────────────────────
# GitHub Utilities
# ─────────────────────────────────────────────────────────────

# 获取 GitHub 仓库的最新 release 版本号
# 用法: gh_latest <owner/repo>
function gh_latest
    if test (count $argv) -eq 0
        echo "Usage: gh_latest <owner/repo>"
        return 1
    end
    gh api "repos/$argv[1]/releases/latest" --jq '.tag_name'
end

# 克隆 GitHub 仓库到 ghq 根目录
# 用法: gh_clone <owner/repo>
function gh_clone
    if test (count $argv) -eq 0
        echo "Usage: gh_clone <owner/repo>"
        return 1
    end
    ghq get "https://github.com/$argv[1]"
end

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

function ghprm --description "Select GitHub PR(s) with fzf and merge them"
    if not command -q gh
        echo "Error: gh is not installed"
        return 1
    end
    if not command -q fzf
        echo "Error: fzf is not installed"
        return 1
    end
    if not command -q jq
        echo "Error: jq is not installed"
        return 1
    end

    set -l selected (
        gh pr list --limit 100 --json number,title,headRefName,author \
        | jq -r '.[] | "\(.number)\t\(.title)\t\(.headRefName)\t@\(.author.login)"' \
        | fzf --height=80% --layout=reverse --border \
              --delimiter='\t' --with-nth=1,2,3,4 \
              --prompt="Select PR(s) to merge > " \
              --multi \
              --bind='tab:toggle+down'
    )

    if test -z "$selected"
        echo "No PR selected"
        return 1
    end

    set -l count (count $selected)
    echo "Merging $count PR(s)..."

    for line in $selected
        set -l pr_number (echo $line | cut -f1)
        if not string match -qr '^[0-9]+$' -- $pr_number
            echo "Error: failed to parse PR number from: $pr_number, skipping"
            continue
        end
        echo "→ Merging PR #$pr_number ..."
        if gh pr merge $pr_number --rebase --delete-branch
            echo "  ✓ PR #$pr_number merged"
        else
            echo "  ✗ PR #$pr_number failed"
        end
    end
end
