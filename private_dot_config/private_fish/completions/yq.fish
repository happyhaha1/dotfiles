# Generate completion from the installed yq version.
if command -q yq
    yq completion fish | source
end
