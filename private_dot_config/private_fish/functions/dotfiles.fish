function dotfiles --description 'Open the chezmoi source directory in the configured editor'
    set editor (set -q EDITOR; and echo $EDITOR; or echo nvim)
    $editor (chezmoi source-path)
end
