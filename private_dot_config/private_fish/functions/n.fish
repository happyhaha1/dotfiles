function n --description 'Open Neovim in the current directory or with the given arguments'
    if test (count $argv) -eq 0
        command nvim .
    else
        command nvim $argv
    end
end
