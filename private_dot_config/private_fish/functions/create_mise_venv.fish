function create_mise_venv --description 'Create a mise-managed Python virtual environment'
    set python_version '3.12'

    if test (count $argv) -gt 0
        set python_version $argv[1]
    end

    echo '[tools]
python = "'$python_version'"

[env]

_.python.venv = { path = ".venv", create = true, uv_create_args = ["--seed"] }' >mise.toml

    mise trust mise.toml
end
