# Generate completion from the installed bat version.
if command -q bat
    bat --completion fish | source
end
