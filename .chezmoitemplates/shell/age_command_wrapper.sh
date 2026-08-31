#!/usr/bin/env bash
set -euo pipefail

# age is needed while chezmoi reads encrypted source state, before any
# run_before/after script can install the rest of the toolchain. macOS:
# prefer the official Homebrew binary. Linux (Omarchy): omarchy-pkg-add
# first, raw pacman as the Arch-family fallback.
for candidate in \
    /opt/homebrew/bin/age \
    /usr/local/bin/age; do
    if [[ -x "$candidate" ]]; then
        exec "$candidate" "$@"
    fi
done

if command -v age >/dev/null 2>&1; then
    exec "$(command -v age)" "$@"
fi

# Linux: Omarchy first (omarchy-pkg-add wraps pacman with a missing-check),
# then raw pacman for any other Arch-family system.
if command -v omarchy-pkg-add >/dev/null 2>&1; then
    omarchy-pkg-add age >/dev/null 2>&1 || true
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm age >/dev/null 2>&1 || true
fi

if command -v age >/dev/null 2>&1; then
    exec "$(command -v age)" "$@"
fi

if command -v brew >/dev/null 2>&1; then
    brew install age >/dev/null 2>&1 || true
fi

for candidate in \
    /opt/homebrew/bin/age \
    /usr/local/bin/age; do
    if [[ -x "$candidate" ]]; then
        exec "$candidate" "$@"
    fi
done

if command -v age >/dev/null 2>&1; then
    exec "$(command -v age)" "$@"
fi

echo "Error: age could not be installed or found (macOS: brew install age; Arch/Omarchy: omarchy pkg add age or sudo pacman -S age)" >&2
exit 1
