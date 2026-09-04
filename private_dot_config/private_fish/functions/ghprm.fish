function ghprm --description 'Select GitHub pull requests with fzf and merge them'
    if not command -q gh
        echo 'Error: gh is not installed'
        return 1
    end
    if not command -q fzf
        echo 'Error: fzf is not installed'
        return 1
    end
    if not command -q jq
        echo 'Error: jq is not installed'
        return 1
    end

    set -l selected (
        gh pr list --limit 100 --json number,title,headRefName,author \
        | jq -r '.[] | "\(.number)\t\(.title)\t\(.headRefName)\t@\(.author.login)"' \
        | fzf --height=80% --layout=reverse --border \
              --delimiter='\t' --with-nth=1,2,3,4 \
              --prompt='Select PR(s) to merge > ' \
              --multi \
              --bind='tab:toggle+down'
    )

    if test -z "$selected"
        echo 'No PR selected'
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
