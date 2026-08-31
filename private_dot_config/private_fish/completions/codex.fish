# Generate completion from the installed Codex version.
if command -q codex
    codex completion fish | source
end
