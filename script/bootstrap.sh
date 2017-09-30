#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)
echo $DOTFILES_ROOT

export all_proxy=http://127.0.0.1:1087
export ftp_proxy=http://127.0.0.1:1087
export http_proxy=http://127.0.0.1:1087
export https_proxy=http://127.0.0.1:1087
install_homebrew () {
  if test ! $(which brew)
  then
    echo "  Installing Homebrew for you..."

    # Install the correct homebrew for each OS type
    if test "$(uname)" = "Darwin"
    then
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    elif test "$(expr substr $(uname -s) 1 5)" = "Linux"
    then
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)"
    fi
  else
      echo "Homebrew Already Install..."
  fi
  brew bundle
}
install_fish () {
    if test ! $(which fish)
    then
        echo "Install fish and oh my fish"
        brew install fish
        echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
        sudo chsh -s /usr/local/bin/fish
    else
        echo "Fish Already Intasll..."
        echo "install fisher"
        curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
        fish $DOTFILES_ROOT/script/installFisher.fish 
    fi
}
set_config() {
    tmuxpowerline="~/.tmux/tmux-powerline"
    if [ -d "$tmuxpowerline" ]; then
        echo "tmux-powerline already..."
    else
        git clone https://github.com/erikw/tmux-powerline.git $tmuxpowerline
    fi
    if [ -f "~/.npmrc" ]; then
      ln -s $DOTFILES_ROOT/.npmrc ~/.npmrc
    else
      echo "npmrc alreay ..."
    fi
}
# install_homebrew
# install_fish
set_config
