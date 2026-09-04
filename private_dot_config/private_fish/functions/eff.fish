function eff --description 'Fuzzy-find a file and open it in the configured editor'
    set -l file (ff)
    set -l ff_status $status

    if test $ff_status -ne 0
        return $ff_status
    end
    if test -z "$file"
        return 0
    end

    set -l editor nvim
    if set -q EDITOR; and test -n "$EDITOR"
        set editor $EDITOR
    end

    command $editor -- "$file"
end
