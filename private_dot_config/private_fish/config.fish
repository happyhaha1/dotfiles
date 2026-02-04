# https://wiki.archlinux.org/title/XDG_Base_Directory
# https://specifications.freedesktop.org/basedir-spec/latest/


set -x XDG_CONFIG_HOME "$HOME/.config"
set -x XDG_STATE_HOME "$HOME/.local/state"
set -x XDG_DATA_HOME "$HOME/.local/share"
set -x XDG_CACHE_HOME "$HOME/.cache"

# https://www.freedesktop.org/wiki/Software/xdg-user-dirs/
set -x XDG_DESKTOP_DIR "$HOME/Desktop"
set -x XDG_DOWNLOAD_DIR "$HOME/Downloads"
set -x XDG_TEMPLATES_DIR "$HOME/Templates"
set -x XDG_PUBLICSHARE_DIR "$HOME/Public"
set -x XDG_DOCUMENTS_DIR "$HOME/Documents"
set -x XDG_MUSIC_DIR "$HOME/Music"
set -x XDG_PICTURES_DIR "$HOME/Pictures"
set -x XDG_VIDEOS_DIR "$HOME/Videos"

# if test (uname) = Darwin
#     eval "$(/opt/homebrew/bin/brew shellenv)"
#     fish_add_path "/opt/homebrew/opt/llvm/bin/"
# end

# docker
set -gx DOCKER_CONFIG "$XDG_CONFIG_HOME/docker"

# hammerspoon
# defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"

# hunspell
# set -gx DICPATH "$XDG_CONFIG_HOME/hunspell/dictionaries"

# keras
# set -gx KERAS_HOME "$XDG_DATA_HOME/keras"

# lean
# set -gx ELAN_HOME "$XDG_DATA_HOME/elan"

# less
# set -gx LESSHISTFILE "$XDG_STATE_HOME/less/history"

# man
# set -x MANPAGER "nvim +Man!"

# npm / node
set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
fish_add_path "./node_modules/.bin"

# OCaml
# set -gx OPAMROOT "$XDG_DATA_HOME/opam"

# This adds: the correct directories to the PATH, auto-completion for the opam binary
# test -r '/Users/sparkes/.share/opam/opam-init/init.fish' && source '/Users/sparkes/.share/opam/opam-init/init.fish' >/dev/null 2>/dev/null; or true

# python
set -gx PYTHONPYCACHEPREFIX "$XDG_CACHE_HOME/python_cache"
set -gx PYTHON_HISTORY "$XDG_CACHE_HOME/python/history"
set -gx IPYTHONDIR "$XDG_CACHE_HOME/ipython"
set -gx MPLCONFIGDIR "$XDG_CACHE_HOME/matplotlib"

# rust
# source "$HOME/.cargo/env.fish"

# etc

## https://fishshell.com/docs/current/faq.html#faq-history
function last_history_item
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item

function fish_should_add_to_history
    # Ignore all uses of the following
    for cmd in man which ls cd z pkgconf pkg-config
        string match -qr "^$cmd" -- "$argv"; and return 1
    end

    # Ignore specific cargo commands
    if string match -qr "^cargo (init)" -- "$argv"
        return 1
    end

    # Ignore specific git
    if string match -qr "^git (add|commit|pop|remove|rename|restore|rm|stash|status|submodule)" -- "$argv"
        return 1
    end

    # Ignore some `-` terminating args
    if string match -qr "\-(v|V|h|H)\$" -- "$argv"
        return 1
    end

    # Ignore some `--` terminating args
    if string match -qr "\-\-(help)\$" -- "$argv"
        return 1
    end

    return 0
end

# fzf
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'

function fzfp
    fzf --layout='default' \
        --ansi \
        --preview-window=top,75%,sharp,wrap \
        --bind 'focus:transform-header:file --brief {}' \
        --bind='ctrl-d:abort' \
        --bind='ctrl-s:change-preview(stat {})' \
        --bind='ctrl-e:change-preview(bat -n --color=always {})' \
        --bind='ctrl-w:toggle-preview'
end

# setup

if status is-interactive
    # Commands to run in interactive sessions can go here
end
starship init fish | source

set -x FZF_DEFAULT_OPTS_FILE $XDG_CONFIG_HOME/fzf/default_ops
# fzf --fish | source

zoxide init fish | source

#direnv hook fish | source