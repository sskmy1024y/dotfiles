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
  if is_exists "brew"; then
    info "Homebrew is already installed"
  else
    warn "Homebrew has not installed yet"
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    info "brew: installed successfully."
  fi

  info "Google Chrome.app"
  brew install --cask "google-chrome"

  info "iTerm2.app"
  brew install --cask "iterm2"

  info "1password.app"
  brew install --cask "1password"
  
  info "Visual Studio Code.app"
  brew install --cask "visual-studio-code"

  info "InteliJ.app"
  brew install --cask "intellij-idea"

  info "Figma.app"
  brew install --cask "figma"

  info "Monitor Control.app"
  brew install --cask monitorcontrol

  info "Initialing AltTab.app"
  brew install alt-tab
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
