# https://wiki.archlinux.org/title/XDG_Base_Directory
# https://specifications.freedesktop.org/basedir-spec/latest/

# Borrow the small, useful Omarchy-Fish defaults while keeping this file
# portable across the macOS machines managed by this repository.
set -gx LANG zh_CN.UTF-8
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR "$EDITOR"
set -gx BAT_THEME ansi
# OpenViking ov CLI: keep its client config under XDG_CONFIG_HOME instead of
# ~/.openviking (server-side state lives on the NAS; only the CLI config is
# local, managed by chezmoi as ~/.config/openviking/ovcli.conf).
set -gx OPENVIKING_CLI_CONFIG_FILE "$XDG_CONFIG_HOME/openviking/ovcli.conf"
set -g fish_greeting
set -g fish_history_max_size 32768
set -x XDG_CONFIG_HOME "$HOME/.config"
set -x XDG_STATE_HOME "$HOME/.local/state"
set -x XDG_DATA_HOME "$HOME/.local/share"
set -x XDG_CACHE_HOME "$HOME/.cache"
# macOS has no /run/user/$UID; keep runtime files under the state dir.
# On Linux the session/logind provides /run/user/$UID — overriding it breaks
# Wayland socket discovery (qs ipc, omarchy-shell, …) in non-session terminals.
if test (uname) = Darwin
    set -x XDG_RUNTIME_DIR "$XDG_STATE_HOME/run"
    if not test -d "$XDG_RUNTIME_DIR"
        mkdir -p "$XDG_RUNTIME_DIR"
    end
end

# --- XDG migration: move tool state out of $HOME (see xdg-ninja) ---
# Toolchains / package managers (data in XDG_DATA_HOME, caches in XDG_CACHE_HOME).
# Original $HOME paths are left as symlinks because some tools hardcode the old paths.
set -gx GRADLE_USER_HOME "$XDG_DATA_HOME/gradle"
set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
set -gx RUSTUP_HOME "$XDG_DATA_HOME/rustup"
set -gx GOPATH "$XDG_DATA_HOME/go"
set -gx MAVEN_USER_HOME "$XDG_DATA_HOME/maven"
set -gx BUN_INSTALL "$XDG_DATA_HOME/bun"
set -gx NPM_CONFIG_CACHE "$XDG_CACHE_HOME/npm"
set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
set -gx CLAUDE_CONFIG_DIR "$XDG_CONFIG_HOME/claude"
set -gx CODEX_HOME "$XDG_CONFIG_HOME/codex"
set -gx GNUPGHOME "$XDG_CONFIG_HOME/gnupg"
set -gx ANDROID_USER_HOME "$XDG_DATA_HOME/android"
set -gx ANDROID_SDK_HOME "$XDG_DATA_HOME/android"
set -gx EASYOCR_MODULE_PATH "$XDG_DATA_HOME/easyocr"
set -gx WGETRC "$XDG_CONFIG_HOME/wget/wgetrc"
set -gx SQLITE_HISTFILE "$XDG_STATE_HOME/sqlite/history"
set -gx LESSHISTFILE "$XDG_STATE_HOME/less/history"
# atuin: db lives in XDG_DATA_HOME; keep $HOME symlink-free
set -gx ATUIN_DATA_DIR "$XDG_DATA_HOME/atuin"
if not test -d "$ATUIN_DATA_DIR"
    mkdir -p "$ATUIN_DATA_DIR"
end

# Keep Aqua binaries first, followed by the official Homebrew prefix. This
# avoids accidentally selecting stale binaries after migration.
if test -d "$XDG_DATA_HOME/aquaproj-aqua/bin"
    fish_add_path "$XDG_DATA_HOME/aquaproj-aqua/bin"
end
for brew_bin in /opt/homebrew/bin /usr/local/bin
    if test -d "$brew_bin"
        fish_add_path "$brew_bin"
    end
end
if type -q brew
    set -l openssl_prefix (brew --prefix openssl@3 2>/dev/null)
    if test -d "$openssl_prefix/bin"
        fish_add_path "$openssl_prefix/bin"
    end
end

set -l aqua_config "$XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml"
set -l aqua_omarchy_config "$XDG_CONFIG_HOME/aquaproj-aqua/aqua-omarchy.yaml"
if test (uname) = Linux; and test -f "$aqua_omarchy_config"
    set aqua_config "$aqua_omarchy_config"
end
if test -f "$aqua_config"
    set -gx AQUA_GLOBAL_CONFIG "$aqua_config"
    set -gx AQUA_CONFIG "$aqua_config"
end

set -l aqua_policy "$XDG_CONFIG_HOME/aquaproj-aqua/aqua-policy.yaml"
if test -f "$aqua_policy"
    set -gx AQUA_POLICY_CONFIG "$aqua_policy"
end

# Keep Moshi on the stable, non-symlink Herdr entrypoint. The wrapper still
# delegates to Aqua, but prevents Moshi from resolving bin/herdr to aqua-proxy.
if test -x "$HOME/.local/bin/herdr"
    set -gx MOSHI_HERDR_PATH "$HOME/.local/bin/herdr"
end

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

# man (same pager used by Omarchy-Fish)
set -gx MANROFFOPT -c
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

# python
set -gx PYTHONPYCACHEPREFIX "$XDG_CACHE_HOME/python_cache"
set -gx PYTHON_HISTORY "$XDG_CACHE_HOME/python/history"
set -gx IPYTHONDIR "$XDG_CACHE_HOME/ipython"
set -gx MPLCONFIGDIR "$XDG_CACHE_HOME/matplotlib"

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

# setup

set -l fzf_default_opts_file "$XDG_CONFIG_HOME/fzf/default_ops"
if test -f "$fzf_default_opts_file"
    set -gx FZF_DEFAULT_OPTS_FILE "$fzf_default_opts_file"
else
    set -e FZF_DEFAULT_OPTS_FILE
end
# Keep an existing options file or inherited value authoritative. Otherwise use
# the same sensible defaults we wanted from Omarchy-Fish.
if not set -q FZF_DEFAULT_OPTS; and not set -q FZF_DEFAULT_OPTS_FILE
    set -gx FZF_DEFAULT_OPTS '--cycle --layout=default --height=90% --preview-window=wrap --marker="*"'
end
# Omarchy-Fish leaves history preview empty so fzf.fish can use its built-in preview.
set -gx fzf_history_opts

if status is-interactive
    # Commands and key bindings below are intentionally interactive-only, as in
    # Omarchy-Fish, so SSH commands and automation remain quiet and fast.
    fish_vi_key_bindings

    if type -q mise
        mise activate fish | source
    end

    if type -q starship
        starship init fish | source
    end

    if type -q zoxide
        zoxide init fish | source
    end

    if type -q atuin
        atuin init fish | source
    end

    if type -q direnv
        direnv hook fish | source
    end

    # Homebrew completions are macOS-only; avoid invoking brew on other hosts.
    if type -q brew
        set -l brew_prefix (brew --prefix 2>/dev/null)
        if test -n "$brew_prefix"
            for brew_fish_dir in \
                "$brew_prefix/share/fish/completions" \
                "$brew_prefix/share/fish/vendor_completions.d"
                if test -d "$brew_fish_dir"
                    set -p fish_complete_path "$brew_fish_dir"
                end
            end
        end
    end

    # Keep the repository's preferred fzf bindings when fzf.fish is available.
    if type -q fzf_configure_bindings
        fzf_configure_bindings --directory=\cf --history=\e\cr
    end

    if type -q _atuin_search
        bind \cr _atuin_search
        bind -M insert \cr _atuin_search
    end

    # Repository picker from functions/_ghq_fzf_cd.fish.
    bind \cg _ghq_fzf_cd
    bind -M insert \cg _ghq_fzf_cd
end

fish_add_path "$HOME/.local/bin"

# Mise activation prepends its shims. Put Aqua's curated CLI subset back at
# the absolute front so migrated tools resolve to Aqua in interactive Fish too.
set -l aqua_bin "$XDG_DATA_HOME/aquaproj-aqua/bin"
function __dotfiles_keep_aqua_first --on-event fish_preexec
    set -l aqua_bin "$XDG_DATA_HOME/aquaproj-aqua/bin"
    if test -d "$aqua_bin"
        set -gx PATH "$aqua_bin" (string match -v -- "$aqua_bin" $PATH)
    end
end

# Run once now as well as after mise's prompt-time environment refresh.
__dotfiles_keep_aqua_first
