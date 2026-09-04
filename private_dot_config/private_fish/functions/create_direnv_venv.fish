function create_direnv_venv --description 'Configure direnv to create a uv virtual environment'
    echo 'layout uv' >.envrc
    direnv allow
end
