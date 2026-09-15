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
info "Install Python"
echo ""

PYTHON_VERSION="3.14.6"

anyenv_on_path() {
  if [ -d "$HOME/.anyenv/bin" ]; then
    export PATH="$HOME/.anyenv/bin:$PATH"
  fi

  local env_dir
  for env_dir in "$HOME"/.anyenv/envs/*; do
    [ -d "$env_dir" ] || continue
    [ -d "$env_dir/bin" ] && export PATH="$env_dir/bin:$PATH"
    [ -d "$env_dir/shims" ] && export PATH="$env_dir/shims:$PATH"
  done

  if [ -d "$HOME/.anyenv/envs/pyenv" ]; then
    export PYENV_ROOT="$HOME/.anyenv/envs/pyenv"
  fi
  return 0
}

anyenv_on_path

# install python
install_python(){
  if is_exists "pyenv"; then
    if [ ! -d "$HOME/.anyenv/envs/pyenv/versions/$PYTHON_VERSION" ]; then
      pyenv install "$PYTHON_VERSION"
    fi
    pyenv global "$PYTHON_VERSION"
    info "Installed python $PYTHON_VERSION"
  else
    warn "pyenv not found. installing..."
    bash "$DOTPATH"/etc/scripts/runtimes/anyenv.sh
    anyenv_on_path
    if ! is_exists "pyenv"; then
      error "pyenv is not available after anyenv install"
      return 1
    fi
    install_python
  fi
}


install_python

if is_exists "pipenv"; then
  info "Installed pipenv."
else
  info "Installing pipenv into the managed Python runtime"
  pyenv exec python -m pip install --upgrade pipenv
  pyenv rehash
fi
