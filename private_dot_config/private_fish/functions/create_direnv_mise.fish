function create_direnv_mise --description 'Configure direnv to use mise'
    echo 'use mise' >.envrc
    direnv allow
end
