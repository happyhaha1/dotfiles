# Generate completion from the installed treefmt version.
if command -q treefmt
    treefmt --completion fish | source
end
