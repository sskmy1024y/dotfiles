#!/usr/bin/env bash

# Configure optional macOS integrations that are not managed by Terraform.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

: "${DOTPATH:=$HOME/.dotfiles}"

. "$DOTPATH/etc/lib/header.sh"

if [ "$(detect_os)" != "darwin" ]; then
  info "Skip optional macOS integrations"
  exit 0
fi

info "Enable sudo authentication with Touch ID"
"$DOTPATH/bin/sudo-via-touch-id.sh"
