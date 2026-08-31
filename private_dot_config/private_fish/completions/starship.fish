# Generate completion from the installed starship version.
if command -q starship
    starship completions fish | source
end
