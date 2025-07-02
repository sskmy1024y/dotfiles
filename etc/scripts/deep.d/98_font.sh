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


if is_exists "fontforge"; then
  info "98 Install fonts..."
else
  error "fontforge required"
  exit 1
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