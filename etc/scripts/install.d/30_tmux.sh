#!/usr/bin/env bash
#
# 30_tmux.sh — Install tmux plugin manager (TPM).
#
# Runs AFTER 00_package.sh / 10_brew.sh so we can assume `git` is on PATH
# at this point. Idempotent: a second run is a no-op.
#
# Author: sskmy1024y

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi

# load lib script (functions)
. "$DOTPATH"/etc/lib/header.sh


echo ""
info "30 Install TPM (tmux plugin manager)"
echo ""

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -d "$TPM_DIR/.git" ]; then
  info "TPM already installed at ${TPM_DIR}"
  exit 0
fi

if ! is_exists "git"; then
  error "git is not installed; cannot fetch TPM"
  error "This should have been installed by 00_package.sh (or 10_brew.sh)."
  exit 1
fi

# If a non-git directory exists (e.g. half-broken state), back it up.
if [ -e "$TPM_DIR" ]; then
  warn "${TPM_DIR} exists but is not a git checkout; moving aside"
  mv "$TPM_DIR" "${TPM_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "$(dirname "$TPM_DIR")"
git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
info "TPM installed at ${TPM_DIR}"
