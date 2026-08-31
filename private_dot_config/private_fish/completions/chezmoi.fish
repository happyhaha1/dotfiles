# Generate completion from the installed chezmoi version.
if command -q chezmoi
    chezmoi completion fish | source
end
