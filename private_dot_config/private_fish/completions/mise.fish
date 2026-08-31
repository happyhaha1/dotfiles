# Generate completion from the installed mise version.
if command -q mise
    mise completion fish | source
end
