# Generate completion from the installed just version.
if command -q just
    just --completions fish | source
end
