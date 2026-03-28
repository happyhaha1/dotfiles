# Fish completion for opencli
# Add to ~/.config/fish/config.fish:  opencli completion fish | source
complete -c opencli -f -a '(
  set -l tokens (commandline -cop)
  set -l cursor (count (commandline -cop))
  opencli --get-completions --cursor $cursor $tokens[2..] 2>/dev/null
)'
