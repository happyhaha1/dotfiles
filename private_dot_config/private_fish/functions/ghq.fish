function ghq --description 'Use fzf when called without arguments; otherwise run ghq normally'
    if test (count $argv) -eq 0
        dev
    else
        command ghq $argv
    end
end
