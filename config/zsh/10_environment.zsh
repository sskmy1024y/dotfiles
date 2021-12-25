## =============================
# * 環境変数
## =============================
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export PATH=$PATH:$HOME/sh
export PATH=$HOME/.local/bin:$PATH
if "$(is_arm_darwin)" ; then
  export PATH=/opt/homebrew/bin:$PATH
  export ZPLUG_HOME=/opt/homebrew/opt/zplug
else
  export ZPLUG_HOME=/usr/local/opt/zplug
fi
export PATH=$HOME/.rbenv/bin:$PATH
export PATH=$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH
