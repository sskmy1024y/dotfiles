#!/usr/bin/env bash

# Author: takuzoo3868
# Last Modified: 17 Feb 2021.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi

# load lib script (functions)
. "$DOTPATH"/etc/lib/header.sh


echo ""
info "22 Install Golang"
echo ""

# install golang
install_golang(){
  if is_exists "goenv"; then
    if [ ! -d "$HOME/.anyenv/envs/goenv/versions/1.16.7" ]; then
      goenv install 1.16.7
      goenv global 1.16.7
    fi
    info "Installed golang 1.16.7"
    source "$HOME"/.zshrc
  else
    warn "goenv not found. installing..."
    install_anyenv
    install_python
  fi
}


install_golang
