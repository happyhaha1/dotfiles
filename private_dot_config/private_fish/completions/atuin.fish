# Generate completion from the installed atuin version.
if command -q atuin
    atuin gen-completions --shell fish | source
end
