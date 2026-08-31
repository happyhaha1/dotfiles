# Generate completion from the installed Git LFS version.
if command -q git-lfs
    git-lfs completion fish | source
end
