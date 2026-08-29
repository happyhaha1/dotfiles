#!/bin/bash
# Bootstrap the macOS dependencies needed before chezmoi reads encrypted state.
#
# This file intentionally starts with a dot. Chezmoi keeps dot-prefixed source
# files out of the managed target state, while the read-source-state hook can
# execute it directly from the source directory.

set -eu

case "$(uname -s)" in
    Darwin) ;;
    *)
        echo ":: bootstrap skipped (this repository currently targets macOS)" >&2
        exit 0
        ;;
esac

info() {
    printf '\033[1;32minfo:\033[0m %s\n' "$1" >&2
}

fail() {
    printf '\033[1;31merror:\033[0m %s\n' "$1" >&2
    exit 1
}

find_brew() {
    local candidate

    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    command -v brew 2>/dev/null || true
}

brew_is_usable() {
    local brew_bin="$1"
    local repository

    repository="$("$brew_bin" --repository 2>/dev/null || true)"
    [ -n "$repository" ] || return 1

    # An official installation has the Homebrew repository checked out with a
    # real Library/Homebrew directory. This also rejects stale package-manager
    # wrappers without naming or depending on that package manager.
    [ -d "$repository/Library/Homebrew" ] &&
        [ ! -L "$repository/Library/Homebrew" ]
}

installer_file=""
cleanup_installer() {
    if [ -n "${installer_file:-}" ]; then
        rm -f "$installer_file"
    fi
}

install_official_homebrew() {
    command -v curl >/dev/null 2>&1 || fail "macOS curl is required to install Homebrew"
    [ -t 0 ] || fail "Homebrew is missing; run chezmoi init --apply from an interactive terminal"

    installer_file="$(mktemp "${TMPDIR:-/tmp}/homebrew-install.XXXXXX")"
    trap cleanup_installer EXIT HUP INT TERM

    info "installing official Homebrew"
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer_file" ||
        fail "failed to download the Homebrew installer"
    /bin/bash "$installer_file" || fail "official Homebrew installation failed"

    cleanup_installer
    trap - EXIT HUP INT TERM
}

brew_bin="$(find_brew)"
if [ -n "$brew_bin" ] && ! brew_is_usable "$brew_bin"; then
    fail "an existing Homebrew command is not an official installation; restore it before running chezmoi"
fi

if [ -z "$brew_bin" ]; then
    install_official_homebrew
    brew_bin="$(find_brew)"
fi

[ -n "$brew_bin" ] || fail "Homebrew was not found after installation"
brew_is_usable "$brew_bin" || fail "Homebrew is not usable at $brew_bin"

brew_prefix="$("$brew_bin" --prefix)" || fail "Homebrew is not usable at $brew_bin"
if [ ! -x "$brew_prefix/bin/age" ]; then
    info "installing age via official Homebrew"
    HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" install age
fi

if [ -x "$brew_prefix/bin/age" ]; then
    info "age is ready: $brew_prefix/bin/age"
    exit 0
fi

fail "age is still unavailable after Homebrew installation"
