# Generate completion from the installed GitHub CLI version.
if command -q gh
    gh completion -s fish | source
end
