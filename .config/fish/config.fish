# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

set -e XDG_CONFIG_HOME  
set -g Z_SCRIPT_PATH (brew --prefix)/etc/profile.d/z.sh
eval (python3 -m virtualfish)
# Load Oh My Fish configuration.
source $OMF_PATH/init.fish
set -gx GOPATH $HOME/Documents/go
set PATH $PATH /usr/local/opt/go/libexec/bin $GOPATH/bin 
