# Generate completion from the installed opencode version.
if command -q opencode
    opencode completion fish | source
end
