# Generate completion from the installed k3d version.
if command -q k3d
    k3d completion fish | source
end
