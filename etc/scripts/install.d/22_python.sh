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
info "22 Install Python"
echo ""

# install python
install_python(){
  if is_exists "pyenv"; then
    if [ ! -d "$HOME/.anyenv/envs/pyenv/versions/2.7.18" ]; then
      pyenv install 2.7.15
    fi
    if [ ! -d "$HOME/.anyenv/envs/pyenv/versions/3.9.1" ]; then
      pyenv install 3.9.1
      pyenv global 3.9.1
    fi
    info "Installed python 2.7 & 3.7"
    exec $SHELL -l
  else
    warn "pyenv not found. installing..."
    install_anyenv
    install_python
  fi
}


install_python

if is_exists "pipenv"; then
  info "Installed pipenv."
else
  brew install pipenv
fi
