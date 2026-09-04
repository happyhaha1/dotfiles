function aicommit --description 'Ask OpenCode to create a Git commit'
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo 'Not a git repository'
        return 1
    end

    if test (count $argv) -eq 0
        set prompt '帮我提交下代码'
    else
        set prompt $argv
    end

    opencode run "$prompt"
end
