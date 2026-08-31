#!/bin/bash

set -eufo pipefail

# Periodic upgrade check (7-day interval)
# The declarative package set is installed by the Homebrew bundle script (02).

LAST_UPDATE_FILE="$HOME/.cache/brew-last-update"
mkdir -p "$(dirname "$LAST_UPDATE_FILE")"
CURRENT_TIME=$(date +%s)
LAST_UPDATE=0
UPDATE_INTERVAL=$((7 * 86400)) # 7 days

[[ -f "$LAST_UPDATE_FILE" ]] && LAST_UPDATE=$(cat "$LAST_UPDATE_FILE")
DAYS_AGO=$(((CURRENT_TIME - LAST_UPDATE) / 86400))

echo ":: [08] Homebrew update check (at most once every 7 days)"

if ! command -v brew >/dev/null 2>&1; then
    echo "    Skipped (Homebrew is not installed)"
    exit 0
fi

if ((CURRENT_TIME - LAST_UPDATE > UPDATE_INTERVAL)); then
    echo "    Last checked ${DAYS_AGO} days ago — overdue, checking for updates..."
    brew update
    echo "$CURRENT_TIME" >"$LAST_UPDATE_FILE"

    outdated=$(brew outdated --greedy)
    if [[ -z "$outdated" ]]; then
        echo "    All packages up to date"
    else
        echo "    Upgrading outdated packages..."
        brew upgrade --greedy
        brew cleanup
    fi
else
    echo "    Skipped (last checked ${DAYS_AGO} days ago; interval is 7 days)"
fi
