#!/usr/bin/env bash

# Author: sskmy1024y
# Last Modified: 13 Aug 2021.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi
LOCALRC=$HOME/.zsh/11_local_environment.zsh

# load lib script (functions)
. "$DOTPATH"/etc/lib/header.sh


clone_or_skip() {
  local repo="$1"
  local dest="$2"

  if [ -d "$dest/.git" ]; then
    info "$(basename "$dest") is already installed"
  elif [ -e "$dest" ]; then
    warn "$dest already exists; skip clone"
  else
    git clone "$repo" "$dest"
  fi
}

install_anyenv() {
  echo ""
  info "20 Install any environment managers"
  echo ""

  if [ -d "$HOME/.anyenv/bin" ]; then
    export PATH="$HOME/.anyenv/bin:$PATH"
  fi

  if is_exists "anyenv"; then
    info "anyenv is already installed"
  else
    warn "anyenv has not installed yet"
    clone_or_skip https://github.com/anyenv/anyenv.git "$HOME"/.anyenv
    export PATH="$HOME/.anyenv/bin:$PATH"

    # plugins
    mkdir -p "$HOME"/.anyenv/plugins
    clone_or_skip https://github.com/znz/anyenv-update.git "$HOME"/.anyenv/plugins/anyenv-update
    clone_or_skip https://github.com/znz/anyenv-git.git "$HOME"/.anyenv/plugins/anyenv-git

    if ! is_exists "anyenv"; then
      error "anyenv command is not available after install"
      return 1
    fi
  fi

  # check exist local bashrc
  if [ ! -f "$LOCALRC" ]; then
    touch "$LOCALRC"
  fi

  if grep -q "### anyenv" "$LOCALRC"; then
    info "anyenv: export PATH is ok"
  else
    warn "anyenv: not export PATH..."
    tee -a "$LOCALRC" <<'EOF'

### anyenv
if [ -d "$HOME"/.anyenv ] ; then
    export PATH="$HOME/.anyenv/bin:$PATH"
    # tmux
    for D in "$HOME"/.anyenv/envs/*/; do
      D=$(basename "$D")
      export PATH="$HOME/.anyenv/envs/${D}/shims:$PATH"
    done
fi

EOF
    # Note: exec will replace the current shell and stop script execution
    # exec $SHELL -l
  fi

  if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/anyenv/anyenv-install" ]; then
    info "anyenv install definitions are already initialized"
  else
    anyenv install --force-init
  fi
  if [ ! -d "${XDG_CONFIG_HOME:-$HOME/.config}/anyenv/anyenv-install" ]; then
    error "anyenv install definitions were not initialized"
    return 1
  fi
  if ! anyenv init - bash >/dev/null 2>&1; then
    warn "anyenv init emitted setup guidance; continuing"
  fi

  for l in goenv pyenv jenv rbenv nodenv; do
    if [ -d "$HOME/.anyenv/envs/$l" ]; then
      info "$l is already installed"
    else
      anyenv install "$l"
    fi
  done
  info "Installed go, python, java, ruby and node environment"
}

install_anyenv
