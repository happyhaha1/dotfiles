# Generate completion from the installed herdr version.
if command -q herdr
    herdr completion fish | source
end
