#!/bin/zsh
## =============================
# * 環境変数
## =============================
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export ZPLUG_HOME=/usr/local/opt/zplug
export PATH=$PATH:$HOME/sh
export PATH=$HOME/.rbenv/bin:$PATH
export PATH=$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH

# TeX Live
export PATH=$PATH:/usr/local/texlive/2019basic/bin/x86_64-darwin/tlmgr

## =============================
# * zplug
## =============================

source $ZPLUG_HOME/init.zsh
zplug 'zsh-users/zsh-completions'
# zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme
zplug romkatv/powerlevel10k, as:theme, depth:1
zplug 'zsh-users/zsh-syntax-highlighting', defer:2
zplug "zsh-users/zsh-autosuggestions" #履歴から予測
if test `hostname` != '%no_root_host%' ; then
  zplug "b4b4r07/enhancd", use:init.sh  # ディレクトリ移動を高速化（fzf であいまい検索）
fi
# 自動インストール
if ! zplug check --verbose; then
  zplug install
fi

### cdr の設定 (zplug load 前に書かないと zaw-cdr がスキップされる)
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook is-at-least
if is-at-least 4.3.10; then
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 5000
zstyle ':chpwd:*' recent-dirs-default yes
fi

### Powerlevel9k
ZSH_THEME="powerlevel9k/powerlevel9k"
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true # 改行を追加
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
# POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=$'\uE0B1' # 左側矢印
# POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=$'\uE0B3' # 右側矢印
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(virtualenv ssh os_icon dir context)  # PROMPT右側
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status vcs) # PROMPT左側

# ICONS (If you see all the icons ` $ get_icon_names`)
POWERLEVEL9K_APPLE_ICON=$'\uF302'
POWERLEVEL9K_HOST_ICON="\uF109 "
POWERLEVEL9K_SSH_ICON="\uF489 "
POWERLEVEL9K_HOME_ICON="\uF015"
POWERLEVEL9K_HOME_SUB_ICON=$'\uF07C'
POWERLEVEL9K_FOLDER_ICON=$'\uF74A'
POWERLEVEL9K_ETC_ICON=$'\uE799'
POWERLEVEL9K_VCS_GIT_GITHUB_ICON=$'\uF408'

POWERLEVEL9K_VCS_BOOKMARK_ICON=$'\uF461 '
POWERLEVEL9K_VCS_BRANCH_ICON=$'\uF418 '
POWERLEVEL9K_VCS_COMMIT_ICON=$'\uF417'
POWERLEVEL9K_VCS_STASH_ICON=$'\uF48D'
POWERLEVEL9K_VCS_STAGED_ICON=$'\uF45E'
POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=$'\uF404 '
POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=$'\uF403 '

POWERLEVEL9K_DIR_HOME_BACKGROUND='036'
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND='038'
POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='202'
POWERLEVEL9K_DIR_ETC_BACKGROUND='007'

DEFAULT_USER='sho'

POWERLEVEL9K_CONTEXT_REMOTE_FOREGROUND='041'
POWERLEVEL9K_CONTEXT_REMOTE_SUDO_BACKGROUND='009'
POWERLEVEL9K_CONTEXT_REMOTE_SUDO_FOREGROUND='231'

# git barnch 表示を設定
POWERLEVEL9K_VCS_CLEAN_BACKGROUND='green'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='cyan'
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'

zplug load

## =============================
# * prompt
## =============================

### 色付けで色の名前が使えたりとか
autoload -Uz add-zsh-hook
autoload -U colors && colors

# ディレクトリの色を設定
export CLICOLOR=true
export LSCOLORS=gxfxxxxxcxxxxxxxxxgxgx
export LS_COLORS='di=01;033:ln=01;35:ex=01;32'


## =============================
# * 補完機能
## =============================

autoload -U compinit; compinit -C

### _oldlist 前回の補完結果を再利用する。
### _complete: 補完する。
### _match: globを展開しないで候補の一覧から補完する。
### _history: ヒストリのコマンドも補完候補とする。
### _ignored: 補完候補にださないと指定したものも補完候補とする。
### _approximate: 似ている補完候補も補完候補とする。
### _prefix: カーソル以降を無視してカーソル位置までで補完する。
#zstyle ':completion:*' completer _oldlist _complete _match _history _ignored _approximate _prefix
zstyle ':completion:*' completer _complete _ignored

# 補完で大文字にもマッチ
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
### 補完候補に色を付ける。
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
## 補完候補をキャッシュする。
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache
## 詳細な情報を使わない
zstyle ':completion:*' verbose no

## sudo の時にコマンドを探すパス
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

function _ssh {
  compadd `fgrep 'Host ' ~/.ssh/config | awk '{print $2}' | sort`;
  compadd `fgrep 'Host ' ~/.ssh/*.conf | awk '{print $2}' | sort`;
}

setopt no_beep  # 補完候補がないときなどにビープ音を鳴らさない。
setopt correct  # コマンドのスペルを訂正する
setopt transient_rprompt  # コマンド実行後は右プロンプトを消す
setopt hist_ignore_dups   # 直前と同じコマンドラインはヒストリに追加しない
setopt hist_ignore_all_dups  # 重複したヒストリは追加しない
setopt hist_reduce_blanks
setopt hist_no_store
setopt hist_verify
setopt share_history  # シェルのプロセスごとに履歴を共有
setopt extended_history  # 履歴ファイルに時刻を記録
setopt auto_cd  # ディレクトリ名だけで移動
chpwd() { ls -ltr }  # cdの後にlsを実行
setopt auto_list  # 補完候補が複数ある時に、一覧表示
setopt auto_menu  # 補完候補が複数あるときに自動的に一覧表示する
setopt complete_in_word  # カーソル位置で補完する。

# コマンド履歴
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000


## =============================
# * エイリアスなど
## =============================
alias ll='ls -l'
alias gitdir='cd ~/sho/Develop/;clear'

eval "$(rbenv init -)"
eval "$(nodenv init -)"


## =============================
# * VSCode Remote SSH
## =============================

# VSCodeのアプリケーションPath
VSCODE_APP_PATH='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app'

# NOTE: クライアントと接続されている有効なVSCODE_IPC_HOOK_CLIがどれかを取得できないため断念。。。
# if [ ! -z "$SSH_TTY" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
#   if [ "$(uname)" = 'Darwin' ]; then
#     export VSCODE_IPC_HOOK_CLI=`ls -t "$(getconf DARWIN_USER_TEMP_DIR)"vscode-ipc-*.sock`
#   else
#     export VSCODE_IPC_HOOK_CLI=$(ls -t /tmp/vscode-ipc-*.sock)
#   fi
#   # FIXME: 暫定対応としてリモート先にインストールされているVSCodeのバージョンに合わせる
#   VSCODE_COMMIT_ID="$(cat ${VSCODE_APP_PATH}/product.json | grep commit | sed 's/^.*"\(.*\)".*$/\1/')"
#   alias code="~/.vscode-server/bin/${VSCODE_COMMIT_ID}/bin/code"
# fi

# codeコマンドがRemote SSHと競合しないように、`/usr/local/bin/`にはインストールせず、環境分岐させる
if [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
  alias code="${VSCODE_APP_PATH}/bin/code"
fi

## =============================
# * その他便利関数
## =============================

#zplugを.zshrcさえ持ってくればインストールできるようにする
function zplug-install (){
	curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
}
