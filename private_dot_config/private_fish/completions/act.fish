# Generate completion from the installed act version.
if command -q act
    act completion fish | source
end
