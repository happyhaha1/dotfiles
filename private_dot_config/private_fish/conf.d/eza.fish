# eza helpers are only for interactive terminals.
# Keep non-interactive fish (SSH commands, automation, Herdr) silent and unmodified.
if not status is-interactive
    return
end

# A dumb terminal does not support the options used by these helpers.
if test "$TERM" = dumb
    return
end

if not command -q eza
    return
end

function _fish_eza_ls --wraps eza
    if set -q eza_params; and test -n "$eza_params"
        set -l params (string split ' ' -- $eza_params)
        command eza $params $argv
    else
        command eza --git \
            --icons \
            --group \
            --group-directories-first \
            --time-style=long-iso \
            --color-scale=all \
            $argv
    end
end

function _fish_eza_auto_ls --on-variable PWD
    if set -q eza_run_on_cd
        _fish_eza_ls
    end
end

alias ls _fish_eza_ls
alias la 'eza -lbhHigUmuSa'
alias lx 'eza -lbhHigUmuSa@'
alias l _fish_eza_l
alias ll _fish_eza_ll
alias llm _fish_eza_llm
alias lt _fish_eza_lt
alias tree _fish_eza_tree

function _fish_eza_l --wraps _fish_eza_ls
    _fish_eza_ls --git-ignore $argv
end

function _fish_eza_ll --wraps _fish_eza_ls
    _fish_eza_ls --all --header --long $argv
end

function _fish_eza_llm --wraps _fish_eza_ls
    _fish_eza_ls --all --header --long --sort=modified $argv
end

function _fish_eza_lt --wraps _fish_eza_ls
    _fish_eza_ls --tree --level=2 $argv
end

function _fish_eza_tree --wraps _fish_eza_ls
    _fish_eza_ls --tree $argv
end
