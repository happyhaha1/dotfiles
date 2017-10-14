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
    else
        echo "Fish Already Intasll..."
        echo "install fisher"
        curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs https://git.io/fisher
        use_ln .config/fish/config.fish
        use_ln .config/fish/alias.fish
        use_ln .config/fish/functions.fish
        fish $DOTFILES_ROOT/script/installFisher.fish 
    fi
}
set_config() {
    tmuxpowerline=$HOME"/.tmux/tmux-powerline"
    if [ -d "$tmuxpowerline" ]; then
        echo "tmux-powerline already..."
    else
        git clone https://github.com/erikw/tmux-powerline.git $tmuxpowerline
    fi
    cp -rf ~/dotfiles/z .config/fish/
    use_ln .yarnrc
    use_ln .npmrc
    use_ln .tmux.conf
    use_ln .ideavimrc
    use_ln .tmux-powerlinerc
    use_ln .gradle/gradle.properties
}

use_ln(){
    config=$HOME"/$1"
    if [ -f "$config" ]; then
      echo "$1 alreay ..."
    #   mv $config $config".bak"
    fi
    ln -s $DOTFILES_ROOT/$1 ~/$1
}
install_vim() {
    if [ -d $HOME"/.SpaceVim" ];then
        echo "alreay .SpaceVim"
    else
        curl -sLf https://spacevim.org/install.sh | bash -s -- --install neovim
        use_ln $DOTFILES_ROOT/.SpaceVim.d $HOME/.SpaceVim.d
        pip2 install neovim --upgrade
        pip3 install neovim --upgrade
    fi
}
install_font() {
    # clone
    git clone https://github.com/powerline/fonts.git --depth=1
    # install
    cd fonts
    ./install.sh
    # clean-up a bit
    cd ..
    rm -rf fonts
}

install_homebrew
install_fish
set_config
install_vim
install_font