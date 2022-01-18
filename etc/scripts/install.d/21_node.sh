#!/usr/bin/env bash

# Author: sskmy1024y
# Last Modified: 13 Aug 2021.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi

# load lib script (functions)
. "$DOTPATH"/etc/lib/header.sh


echo ""
info "21 Install Node"
echo ""

# install python
install_node(){
  if is_exists "nodenv"; then
    if [ ! -d "$HOME/.anyenv/envs/nodenv/versions/16.4.0" ]; then
      nodenv install 16.4.0
      nodenv global 16.4.0
    fi
    info "Installed node 16.4.0"
    exec $SHELL -l
  else
    warn "nodenv not found. installing..."
    install_anyenv
    install_node
  fi
}

install_node

if is_exists "yarn"; then
  info "Installed yarn."
else
  npm install -g yarn
fi
