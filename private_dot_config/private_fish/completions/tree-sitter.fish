# Generate completion from the installed tree-sitter version.
if command -q tree-sitter
    tree-sitter complete --shell fish | source
end
