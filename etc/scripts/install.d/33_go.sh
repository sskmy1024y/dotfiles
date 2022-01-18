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


echo ""
info "22 Install Golang"
echo ""

# curl -LO "https://get.golang.org/$(uname)/go_installer"
# chmod +x go_installer
# ./go_installer
# rm go_installer

# export PATH=$PATH:$HOME/.go/bin
# export GOPATH=$HOME/go
# export PATH=$PATH:$GOPATH/bin

# mkdir -p $HOME/src $HOME/bin

# go get github.com/x-motemen/ghq
# go get github.com/peco/peco/cmd/peco
