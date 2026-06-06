#!/usr/bin/env bash
#
# 98_font.sh — Install the Cica programming font.
#
# Cica ships from upstream already merged with Nerd Fonts glyphs (and
# optionally Noto Color Emoji), so we do NOT need fontforge / nerd-fonts /
# font-patcher. We just download the latest release zip and drop its *.ttf
# files into the OS font directory.
#
# Other Nerd Fonts (Meslo, JetBrains Mono, Hack, FiraCode, ...) are installed
# via Homebrew casks from the Brewfile on macOS; this script handles only the
# one font that isn't packaged for brew.

# Author: takuzoo3868
# Last Modified: 06 Jun 2026.

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

echo ""
info "98 Install Cica font (already Nerd-Font-patched upstream)"
echo ""

# Pick OS-appropriate user font directory.
case "$(detect_os)" in
  darwin) fonts_dir="$HOME/Library/Fonts" ;;
  ubuntu|archlinux|linux) fonts_dir="$HOME/.local/share/fonts" ;;
  *) fonts_dir="$HOME/.fonts" ;;
esac
mkdir -p "$fonts_dir"

# Stage downloads under a self-cleaning temp dir so we never leave partial
# zips behind in $DOTPATH/tmp.
tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

# Resolve the latest "with emoji" release zip. miiton/Cica ships two zips per
# release; the default (no "_without_emoji" suffix) bundles Noto Color Emoji.
# We use grep -v rather than grep "with_emoji" because the naming convention
# changed in v5: the with-emoji build no longer has a suffix at all.
if ! api_json=$(curl -fsSL https://api.github.com/repos/miiton/Cica/releases/latest); then
  warn "Failed to query Cica releases from GitHub API (rate-limited?); skipping Cica install."
  exit 0
fi

cica_url=$(printf '%s' "$api_json" \
  | grep '"browser_download_url".*\.zip"' \
  | grep -v "without_emoji" \
  | head -n 1 \
  | cut -d '"' -f 4)

if [ -z "$cica_url" ]; then
  warn "Could not resolve a Cica zip URL from GitHub API; skipping Cica install."
  exit 0
fi

info "Downloading Cica from $cica_url"
if ! curl -fsSL "$cica_url" -o "$tmp_dir/cica.zip"; then
  warn "Cica download failed; skipping Cica install."
  exit 0
fi

# `unzip` ships with macOS by default and is in the base install on most
# Linux distros; if it ever isn't, surface that as a hard error so a real
# install doesn't silently skip the font.
if ! command -v unzip >/dev/null 2>&1; then
  error "unzip not found; install it (e.g. 'apt install unzip') and retry."
  exit 1
fi

unzip -q -o "$tmp_dir/cica.zip" -d "$tmp_dir/cica"

# Copy every .ttf the archive contains into the user font dir. -f overwrites
# stale copies (e.g. upgrading from a previous version).
found=0
while IFS= read -r -d '' ttf; do
  cp -f "$ttf" "$fonts_dir/"
  found=$((found + 1))
done < <(find "$tmp_dir/cica" -type f -name '*.ttf' -print0)

if [ "$found" -eq 0 ]; then
  warn "Cica zip contained no .ttf files (unexpected); leaving fonts untouched."
  exit 0
fi

# macOS: nudge the font registration daemon so apps pick up the new family
# without requiring a logout. Best-effort only.
if [ "$(detect_os)" = "darwin" ]; then
  atsutil databases -remove >/dev/null 2>&1 || true
fi

info "Installed ${found} Cica .ttf file(s) into ${fonts_dir}"
