# Generate completion from the installed glow version.
if command -q glow
    glow completion fish | source
end
