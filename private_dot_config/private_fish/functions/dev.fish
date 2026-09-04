function dev --description 'Select a ghq repository with fzf and enter it'
    set ghq_root (ghq root)
    set editor (set -q EDITOR; and echo $EDITOR; or echo nvim)

    set repo (
        ghq list | fzf \
            --query=(test (count $argv) -gt 0; and echo $argv[1]; or echo '') \
            --preview "
            set repo_path $ghq_root/{}
            echo -e '\033[1;34m📁 {}\033[0m'
            echo ''
            if test -d \$repo_path/.git
                set branch (git -C \$repo_path branch --show-current 2>/dev/null)
                echo -e '\033[1;33m⎇ \$branch\033[0m'
                echo ''
            end
            eza --tree --level=2 --color=always --icons --git-ignore \$repo_path 2>/dev/null
            echo ''
            for readme in \$repo_path/README \$repo_path/README.md \$repo_path/README.rst \$repo_path/README.txt \$repo_path/readme \$repo_path/readme.md
                if test -f \$readme
                    echo -e '\033[1;32m📖 README\033[0m'
                    bat --color=always --style=plain --line-range=:20 \$readme 2>/dev/null
                    break
                end
            end
            " \
            --preview-window='right:55%:border-left:wrap' \
            --header='Enter: cd | Ctrl+O: VS Code | Ctrl+E: Editor | Ctrl+Y: copy path | Ctrl+D: delete' \
            --bind="ctrl-o:execute-silent(code $ghq_root/{})" \
            --bind="ctrl-e:execute($editor $ghq_root/{})" \
            --bind="ctrl-y:execute-silent(echo $ghq_root/{} | pbcopy)+abort" \
            --bind="ctrl-d:execute(
                set repo_path '$ghq_root/{}'
                echo ''
                echo '即将删除: ' \$repo_path
                echo '确认删除请输入 y: '
                read confirm
                if test \"\$confirm\" = y
                    rm -rf \"\$repo_path\"
                    echo '已删除: ' \$repo_path
                else
                    echo '已取消'
                end
                sleep 1
            )+reload(ghq list)"
    )

    if test -n "$repo"
        cd $ghq_root/$repo; or return 1
        if test -n "$TMUX"
            tmux rename-session (string split -r -m1 / "$repo")[-1]
        end
    end
end
