function gcfzf
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Not a git repository"
        return 1
    end

    set selected (
        git for-each-ref --format='%(refname:short)' refs/heads refs/remotes \
        | grep -vE '.*/HEAD$' \
        | sort -u \
        | fzf --prompt="Checkout branch > "
    )

    if test -z "$selected"
        return 0
    end

    # 本地分支：直接切换
    if git show-ref --verify --quiet "refs/heads/$selected"
        git switch "$selected"
        return $status
    end

    # 远程分支：自动创建并跟踪本地分支
    if string match -rq '.+/.+' -- "$selected"
        set remote (string split -m 1 / "$selected")[1]
        set branch (string split -m 1 / "$selected")[2]

        # 如果本地分支已存在，直接切换
        if git show-ref --verify --quiet "refs/heads/$branch"
            git switch "$branch"
        else
            git switch -c "$branch" --track "$selected"
        end
        return $status
    end

    echo "Unknown branch selection: $selected"
    return 1
end
