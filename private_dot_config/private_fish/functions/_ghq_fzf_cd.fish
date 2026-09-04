function _ghq_fzf_cd --description 'Select a ghq repository with fzf and change directory'
    set repo (
        ghq list | fzf \
            --height=40% \
            --reverse \
            --preview 'eza --tree --level=1 --color=always --icons "(ghq root)/{}"' \
            --preview-window='right:40%:border-left'
    )
    if test -n "$repo"
        cd (ghq root)/$repo
        commandline -f repaint
    end
end
