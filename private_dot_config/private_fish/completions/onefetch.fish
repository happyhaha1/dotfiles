# Generate completion from the installed onefetch version.
if command -q onefetch
    onefetch --generate fish | source
end
