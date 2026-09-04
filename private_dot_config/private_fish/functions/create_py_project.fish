function create_py_project --description 'Create a Python project with uv and direnv'
    set name (test (count $argv) -gt 0; and echo $argv[1]; or echo '.')

    if test "$name" != '.'
        mkdir -p "$name" && cd "$name" || return 1
    end

    uv init
    create_direnv_venv
    echo 'Python project created!'
end
