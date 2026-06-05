#!/usr/bin/env bash

# Author: takuzoo3868
# Last Modified: 15 Feb 2021.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi

# load lib script (functions)
# shellcheck source=/dev/null
# shellcheck disable=SC1091
. "$DOTPATH"/etc/lib/header.sh
# shellcheck source=/dev/null
# shellcheck disable=SC1091
. "$DOTPATH"/etc/lib/macos.sh

# On macOS, make sure brew is on PATH for the current shell — `make init` adds
# /opt/homebrew/bin via ~/.zprofile, but a fresh `make deep` shell hasn't
# sourced that yet.
if [ "$(detect_os)" = "darwin" ]; then
  brew_on_path
fi

if is_exists "fontforge"; then
  info "98 Install fonts..."
else
  # fontforge missing — try to install it via brew (macOS) rather than failing
  # outright. Lets `make deep` succeed even when fontforge isn't in Brewfile or
  # `make init` was skipped.
  if [ "$(detect_os)" = "darwin" ] && is_exists "brew"; then
    info "fontforge not found — installing via brew..."
    brew install fontforge
  fi

  if ! is_exists "fontforge"; then
    error "fontforge required (install: 'brew install fontforge' on macOS, or your distro's package)"
    exit 1
  fi
  info "98 Install fonts..."
fi

mkdir -p "$DOTPATH/tmp" && cd "$DOTPATH/tmp"

# Download Nerd fonts
nerd_url="https://github.com/ryanoasis/nerd-fonts.git"
git clone --depth 1 "$nerd_url" && cd nerd-fonts && mkdir -p orig dist

# Download Cica fonts
cica_url=$(curl -s https://api.github.com/repos/miiton/Cica/releases/latest | grep "browser_download_url.*zip" | grep "with_emoji" | cut -d '"' -f 4)
curl -L "$cica_url" | tar -xvz -C orig

# Cica fonts repatched mapping
find orig/ -type f -name "*.ttf" -print0 | while IFS= read -r -d '' font; do
  fontforge -script font-patcher -c "$font" --out dist
done

# Rename whitespace to underscore
find dist -type f -name "*.ttf" | while IFS= read -r org_name; do
  new_name="${org_name// /_}"
  mv "$org_name" "$new_name"
done

# Copy to font directory
# Set fonts_dir based on OS
case "$(detect_os)" in
  darwin) fonts_dir="$HOME/Library/Fonts" ;;
  linux) fonts_dir="$HOME/.local/share/fonts" ;;
  *) fonts_dir="$HOME/.fonts" ;;
esac

mkdir -p "$fonts_dir"
cp -u dist/* "$fonts_dir"

cd "$DOTPATH"
rm -rf tmp