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


install_anyenv() {
  echo ""
  info "20 Install any environment managers"
  echo ""

  if is_exists "anyenv"; then
    info "anyenv is already installed"
  else
    warn "anyenv has not installed yet"
    if [ -z "${HOME}/.anyenv" ]; then
      git clone https://github.com/anyenv/anyenv.git "$HOME"/.anyenv
    fi

    # plugins
    mkdir -p "$HOME"/.anyenv/plugins
    git clone https://github.com/znz/anyenv-update.git "$HOME"/.anyenv/plugins/anyenv-update
    git clone https://github.com/znz/anyenv-git.git "$HOME"/.anyenv/plugins/anyenv-git

    source ~/.zshrc
  fi

  # check exist local bashrc
  if [ ! -f "$LOCALRC" ]; then
    touch "$LOCALRC"
  fi

  if grep -q "### anyenv" "$LOCALRC"; then
    info "anyenv: export PATH is ok"
  else
    warn "anyenv: not export PATH..."
    tee -a "$LOCALRC" <<EOF

### anyenv
if [ -d "$HOME"/.anyenv ] ; then
    export PATH="$HOME/.anyenv/bin:$PATH"
    # tmux
    for D in $(ls "$HOME"/.anyenv/envs); do
      export PATH="$HOME/.anyenv/envs/${D}/shims:$PATH"
    done
fi

EOF
    # shellcheck disable=SC1091
    exec $SHELL -l
  fi

  "$HOME"/.anyenv/bin/anyenv init
  # exec $SHELL -l
  exec $SHELL -l
  anyenv install --init

  for l in goenv pyenv jenv rbenv nodenv; do
    anyenv install $l
  done
  info "Installed go, python, java, ruby and node environment"
}

install_anyenv
