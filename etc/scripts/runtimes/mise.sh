#!/usr/bin/env bash

# Author: sskmy1024y
# Description: Install mise and the language runtimes declared in config/mise/config.toml.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi

# load lib script (functions)
. "$DOTPATH"/etc/lib/header.sh

MISE_BIN_DIR="$HOME/.local/bin"
MISE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml"

echo ""
info "Install runtimes with mise"
echo ""

mise_on_path() {
  is_exists mise && return 0

  if [ -x "$MISE_BIN_DIR/mise" ]; then
    export PATH="$MISE_BIN_DIR:$PATH"
    return 0
  fi
  return 1
}

install_mise() {
  if mise_on_path; then
    info "mise is already installed: $(command -v mise)"
    return 0
  fi

  warn "mise has not installed yet"
  if [ "$(detect_os)" = "darwin" ] && is_exists brew; then
    brew install mise
  elif is_exists curl; then
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_BIN_DIR/mise" sh
  elif is_exists wget; then
    wget -qO- https://mise.run | MISE_INSTALL_PATH="$MISE_BIN_DIR/mise" sh
  else
    error "curl or wget is required to install mise"
    return 1
  fi

  if ! mise_on_path; then
    error "mise command is not available after install"
    return 1
  fi
}

install_tools() {
  # Use the repository config directly when `dotfiles sync` has not linked it yet.
  if [ ! -e "$MISE_CONFIG" ]; then
    warn "$MISE_CONFIG not found; using $DOTPATH/config/mise/config.toml"
    export MISE_GLOBAL_CONFIG_FILE="$DOTPATH/config/mise/config.toml"
  fi

  # Run from $HOME so a project mise.toml in the caller's cwd is not applied.
  (cd "$HOME" && mise install --yes)
  info "Installed tools:"
  (cd "$HOME" && mise ls --current)
}

install_mise
install_tools
