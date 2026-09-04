function ff --wraps=fzf --description 'Fuzzy-find files with a bat preview'
    if not command -q fzf
        echo 'Error: fzf is not installed' >&2
        return 127
    end

    if command -q bat
        command fzf --preview 'bat --style=numbers --color=always -- {}' $argv
    else
        command fzf $argv
    end
end
