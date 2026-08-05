#!/usr/bin/env bash
set -euo pipefail

AGE_BIN="$HOME/.nix-profile/bin/age"

# Prefer the profile-managed age binary. This is important during the first
# chezmoi run: an older age already in PATH may not understand SSH identities.
if [[ -x "$AGE_BIN" ]]; then
    exec "$AGE_BIN" "$@"
fi

# Source nix environment if not already available.
if ! command -v nix >/dev/null 2>&1; then
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck disable=SC1091
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

# Install age once into user profile, then execute the profile binary.
if command -v nix >/dev/null 2>&1; then
    nix --extra-experimental-features 'nix-command flakes' profile add "nixpkgs#age" >/dev/null || true
    if [[ -x "$AGE_BIN" ]]; then
        exec "$AGE_BIN" "$@"
    fi
fi

# Homebrew is the fallback on machines without a usable Nix profile.
if command -v brew >/dev/null 2>&1; then
    brew install age >/dev/null 2>&1 || true
fi
if command -v age >/dev/null 2>&1; then
    exec "$(command -v age)" "$@"
fi

echo "Error: age could not be installed or found" >&2
exit 1
