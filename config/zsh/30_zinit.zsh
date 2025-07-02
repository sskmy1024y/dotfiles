## =============================
# * zinit
## =============================

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

## =============================
# * Configurations
## =============================

## コマンド補完
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' ## 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*:default' menu select=1 ## 補完候補を一覧表示したとき、Tabや矢印で選択できるようにする

zinit ice wait'0'; zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting ## シンタックスハイライト
zinit light zsh-users/zsh-autosuggestions ## 履歴補完
zinit ice depth=1; zinit light romkatv/powerlevel10k ## powerlevel10k
zinit light paulirish/git-open

## 履歴保存管理
HISTFILE=$ZDOTDIR/.zsh-history
HISTSIZE=100000
SAVEHIST=1000000

## 他のzshと履歴を共有
setopt inc_append_history
setopt share_history

## パスを直接入力してもcdする
setopt AUTO_CD

## 環境変数を補完
setopt AUTO_PARAM_KEYS

autoload -Uz compinit && compinit
