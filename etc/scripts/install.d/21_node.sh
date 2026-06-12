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

NODE_VERSION="24.16.0"

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

  if [ -d "$HOME/.anyenv/envs/nodenv" ]; then
    export NODENV_ROOT="$HOME/.anyenv/envs/nodenv"
    [ -d "$NODENV_ROOT/plugins/node-build/bin" ] && export PATH="$NODENV_ROOT/plugins/node-build/bin:$PATH"
  fi
  return 0
}

clone_or_skip() {
  local repo="$1"
  local dest="$2"

  if [ -d "$dest/.git" ]; then
    info "$(basename "$dest") is already installed"
  elif [ -e "$dest" ]; then
    warn "$dest already exists; skip clone"
  else
    git clone "$repo" "$dest"
  fi
}

anyenv_on_path

# install python
install_node(){
  if is_exists "nodenv"; then
    if [ ! -d "$HOME/.anyenv/envs/nodenv/versions/$NODE_VERSION" ]; then
      nodenv install "$NODE_VERSION"
    fi
    nodenv global "$NODE_VERSION"
    info "Installed node $NODE_VERSION"
  else
    warn "nodenv not found. installing..."
    bash "$DOTPATH"/etc/scripts/install.d/20_anyenv.sh
    anyenv_on_path
    if ! is_exists "nodenv"; then
      error "nodenv is not available after anyenv install"
      return 1
    fi
    install_node
  fi
}

install_node

if is_exists "nodenv"; then
  mkdir -p "$(nodenv root)/plugins"
  clone_or_skip https://github.com/nodenv/nodenv-package-json-engine.git "$(nodenv root)/plugins/nodenv-package-json-engine"
fi
