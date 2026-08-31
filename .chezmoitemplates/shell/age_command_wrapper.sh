#!/usr/bin/env bash
set -euo pipefail

# age is needed while chezmoi reads encrypted source state, before any
# run_before/after script can install the rest of the toolchain. Prefer the
# official Homebrew binary and keep this wrapper independent of package
# managers other than Homebrew.
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

echo "Error: age could not be installed or found (install official Homebrew + age first)" >&2
exit 1
