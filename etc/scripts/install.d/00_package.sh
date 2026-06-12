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


echo ""
info "00 Install Dev packages"
echo ""

PKG_DEFAULT="git tmux curl zsh"

ubuntu() {
  PKG_UBUNTU="peco openssh-server libssl-dev locales-all"

  sudo apt update -q -y
  sudo apt upgrade -y
  # shellcheck disable=SC2086
  sudo apt install -q -y $PKG_DEFAULT
  # shellcheck disable=SC2086
  sudo apt install -q -y $PKG_UBUNTU
}

archlinux() {
  PKG_ARCH="ghq peco hub sakura fzf p7zip neovim python2-neovim python-pynvim llvm baobab radare2 weechat ranger"

  if ! has yay; then
    warn "yay has not installed yet."
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si
  fi
  
  yay -Syu --noconfirm
  # shellcheck disable=SC2086
  yay -S --needed $PKG_DEFAULT
  # shellcheck disable=SC2086
  yay -S --needed $PKG_ARCH
}

darwin() {
  # Step 1: Xcode Command Line Tools (provides git/clang/make).
  # Uses the non-interactive softwareupdate path — never spawns a GUI.
  if ! ensure_xcode_clt; then
    error "Cannot continue without Xcode Command Line Tools."
    exit 1
  fi

  # Step 2: Homebrew. Idempotent; also fixes PATH for the current shell.
  if ! ensure_homebrew; then
    error "Cannot continue without Homebrew."
    exit 1
  fi

  # Step 3: default packages via brew. Existing outdated formulas may be
  # upgraded when the Homebrew prefix is writable.
  # shellcheck disable=SC2086
  brew_install_default_formulas $PKG_DEFAULT
}

android() {
  PKG_ANDROID="ncurses-utils binutils coreutils file grep wget taskwarrior neovim"

  pkg update
  # shellcheck disable=SC2086
  pkg install $PKG_DEFAULT
  # shellcheck disable=SC2086
  pkg install $PKG_ANDROID
  termux-setup-storage
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
