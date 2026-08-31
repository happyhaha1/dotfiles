# Generate completion from the installed zellij version.
if command -q zellij
    zellij setup --generate-completion fish | source
end
