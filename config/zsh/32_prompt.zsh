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

