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
    local unwritable_paths
    unwritable_paths="$(brew_unwritable_paths)"
    if [ -n "$unwritable_paths" ]; then
      if brew bundle check --file Brewfile >/dev/null 2>&1; then
        warn "brew: Brewfile dependencies are already installed, but Homebrew has unwritable directories; skip bundle upgrades"
        warn "brew: fix ownership later if you want brew bundle to upgrade during init:"
        printf "%s\n" "$unwritable_paths" | sed 's/^/  /'
      else
        error "brew: Homebrew has unwritable directories and Brewfile dependencies are missing"
        printf "%s\n" "$unwritable_paths" | sed 's/^/  /'
        error "brew: fix these paths, then rerun make init"
        return 1
      fi
      builtin cd "$DOTPATH"
      return 0
    fi

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
