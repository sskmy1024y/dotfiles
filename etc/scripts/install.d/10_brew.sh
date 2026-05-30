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
. "$DOTPATH"/etc/lib/macos.sh


brewery() {
  echo ""
  info "10 Brew bundle"
  echo ""

  # Defensive: ensure CLT + brew are present. Normally 00_package.sh has
  # already done this, but running 10_brew.sh standalone should also work.
  if ! ensure_xcode_clt; then
    error "Cannot continue without Xcode Command Line Tools."
    return 1
  fi
  if ! ensure_homebrew; then
    error "Cannot continue without Homebrew."
    return 1
  fi

  builtin cd "$DOTPATH"/etc/scripts/install.d
  if [ ! -f Brewfile ]; then
    error "Brewfile: not found"
  else
    brew bundle
    info "brew: tapped successfully."
  fi
  builtin cd "$DOTPATH"
}

case $(detect_os) in
  darwin)
    brewery ;;
  *)
    info "Skip 10-brew" ;;
esac
