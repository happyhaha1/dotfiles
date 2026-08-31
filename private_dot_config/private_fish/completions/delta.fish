# Generate completion from the installed delta version.
if command -q delta
    delta --generate-completion fish | source
end
