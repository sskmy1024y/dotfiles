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

install_cask_app() {
  local cask="$1"
  local app_path="$2"
  local label="$3"

  info "$label"

  if brew list --cask --versions "$cask" >/dev/null 2>&1; then
    info "$label is already installed by Homebrew"
    return 0
  fi

  if [ -e "$app_path" ]; then
    warn "$app_path already exists; skip brew cask install"
    return 0
  fi

  brew install --cask "$cask"
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

  install_cask_app "arc" "/Applications/Arc.app" "Arc.app"
  install_cask_app "warp" "/Applications/Warp.app" "Warp.app"
  install_cask_app "1password" "/Applications/1Password.app" "1Password.app"
  install_cask_app "visual-studio-code" "/Applications/Visual Studio Code.app" "VS Code.app"
  install_cask_app "figma" "/Applications/Figma.app" "Figma.app"
  install_cask_app "raycast" "/Applications/Raycast.app" "Raycast.app"
  install_cask_app "alt-tab" "/Applications/AltTab.app" "AltTab.app"
  install_cask_app "codex" "/Applications/Codex.app" "Codex.app"
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
