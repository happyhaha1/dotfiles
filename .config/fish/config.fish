set -g fnm_mirror http://npm.taobao.org/mirrors/node

eval (python3 -m virtualfish)
set -g XDG_CONFIG_HOME ~/.config
source ~/.config/fish/functions.fish
source ~/.config/fish/alias.fish

set proxy_host 127.0.0.1:1087
set -gx GOPATH $HOME/Documents/go
set PATH $PATH /usr/local/opt/go/libexec/bin $GOPATH/bin 
set -g theme_color_scheme base16
set -g theme_display_ruby yes
set -g theme_git_worktree_support yes

