#!/usr/bin/env bash

# Author: sskmy1024y
# Last Modified: 14 Jan 2022.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi

# load lib script (functions)
. "$DOTPATH"/etc/lib/header.sh
. "$DOTPATH"/etc/lib/macos.sh


echo ""
info "97 Install applications via brew"
echo ""

ubuntu() {
  echo ""
}

archlinux() {
  echo ""
}

darwin() {
  # Defensive: same pattern as install.d/10_brew.sh. Running deep.d standalone
  # (e.g. on a fresh VM where `make init` didn't add brew to the current
  # shell's PATH) must still work without GUI prompts.
  if ! ensure_xcode_clt; then
    error "Cannot continue without Xcode Command Line Tools."
    return 1
  fi
  if ! ensure_homebrew; then
    error "Cannot continue without Homebrew."
    return 1
  fi

  info "Arc.app"
  brew install --cask "arc"

  info "Warp.app"
  brew install --cask "warp"

  info "1password.app"
  brew install --cask "1password"

  info "VS Code.app"
  brew install --cask "visual-studio-code"

  info "InteliJ.app"
  brew install --cask "intellij-idea"

  info "Figma.app"
  brew install --cask "figma"

  info "Raycast.app"
  brew install --cask raycast

  info "AltTab.app"
  brew install --cask alt-tab
}

android() {
  echo ""
}

case $(detect_os) in
  ubuntu)
    ubuntu ;;
  archlinux)
    archlinux ;;
  darwin)
    darwin ;;
  android)
    android ;;
esac
