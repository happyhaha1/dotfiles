function fgc --description 'Select a Git branch with fzf and check it out'
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo 'Not a git repository'
        return 1
    end

    set branch (
        git branch -a --color=always \
        | grep -v '/HEAD' \
        | fzf --ansi --preview 'git log --oneline --graph --color=always {1}' \
        | string trim \
        | string replace -r '^\*\s*' '' \
        | string replace 'remotes/origin/' ''
    )

    if test -z "$branch"
        return 0
    end

    git checkout "$branch"
end
