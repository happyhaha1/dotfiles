# Generate completion from the installed pueue version.
if command -q pueue
    pueue completions fish | source
end
