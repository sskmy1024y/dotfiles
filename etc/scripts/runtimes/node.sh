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
info "Install Node"
echo ""

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

node_build_plugin_dir() {
  if is_exists "nodenv"; then
    printf "%s/plugins/node-build\n" "$(nodenv root)"
  else
    printf "%s/.anyenv/envs/nodenv/plugins/node-build\n" "$HOME"
  fi
}

update_node_build() {
  local node_build_dir

  node_build_dir="$(node_build_plugin_dir)"
  info "Updating node-build definitions..."

  if [ ! -d "$node_build_dir/.git" ]; then
    error "node-build plugin repository not found: $node_build_dir"
    return 1
  fi

  git -C "$node_build_dir" pull --ff-only
}

latest_stable_node_version() {
  # `nodenv install --list` is sorted and contains the latest stable release
  # for each maintained Node major. Other runtimes such as GraalJS may also
  # appear, so only accept plain Node semantic versions.
  nodenv install --list 2>/dev/null |
    awk '$1 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ { latest = $1 } END { print latest }'
}

# install node
install_node(){
  local node_version

  if is_exists "nodenv"; then
    update_node_build
    node_version="$(latest_stable_node_version)"
    if [ -z "$node_version" ]; then
      error "Could not determine the latest stable Node version"
      return 1
    fi

    if [ ! -d "$(nodenv root)/versions/$node_version" ]; then
      nodenv install "$node_version"
    fi
    nodenv global "$node_version"
    info "Installed node $node_version"
  else
    warn "nodenv not found. installing..."
    bash "$DOTPATH"/etc/scripts/runtimes/anyenv.sh
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
