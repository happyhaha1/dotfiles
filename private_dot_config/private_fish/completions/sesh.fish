# Generate completion from the installed sesh version.
if command -q sesh
    sesh completion fish | source
end
