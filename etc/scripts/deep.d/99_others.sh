#!/usr/bin/env bash

# Author: sskmy1024y
# Last Modified: 13 Aug 2021.

trap 'echo Error: $0:$LINENO stopped; exit 1' ERR INT
set -euo pipefail

# set dotfiles path as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=$HOME/.dotfiles; export DOTPATH
fi

# load lib script (functions)
. "$DOTPATH"/etc/lib/header.sh


echo ""
info "99 Deploy other settings"
echo ""

ubuntu() {
}

archlinux() {
}

darwin() {
  info "Initialing key repeat speed"
  defaults write -g InitialKeyRepeat -int 10
  defaults write -g KeyRepeat -int 1

  info "Initializing Dock layout"
  defaults write com.apple.dock tilesize -integer 46
  defaults write com.apple.dock size-immutable -boolean true

  info "Initializing Launchpad layout"
  defaults write com.apple.dock springboard-columns -int 7
  defaults write com.apple.dock springboard-rows -int 6

  info "Initializing Finder"
  # ネットワークディスクに.DS_Storeを作らない
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  # 印刷終了時にプリンターアプリを終了させる
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
  # workspaceの遷移時のディレイを高速化(デフォルトは->) defaults delete com.apple.dock expose-animation-duration
  defaults write com.apple.dock expose-animation-duration -float 0.15
  # Quicklookのプレビュー再生を続ける
  defaults write com.apple.finder AutoStopWhenSelectionChanges -bool false
  # すべてのアプリケーションを許可
  sudo spctl --master-disable

  info "Initializing sudo via TouchID"
  "$DOTPATH"/bin/sudo-via-touch-id.sh

  info "Restarting Dock"
  killall Dock

  info "Restarting Finder"
  killall Finder
}

android() {
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
