#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)
echo $DOTFILES_ROOT


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
}
install_fish () {
    if test ! $(which fish)
    then
        echo "Install fish and oh my fish"
        brew install fish
        echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
        sudo chsh -s /usr/local/bin/fish
        curl -L https://get.oh-my.fish | fish
    else
        echo "Fish Already Intasll..."
    fi
}

install_homebrew
# install_fish
