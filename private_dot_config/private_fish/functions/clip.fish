function clip --description 'Copy standard input to the system clipboard'
    if test (uname) = Darwin
        pbcopy
    else
        xclip -selection clipboard
    end
end
