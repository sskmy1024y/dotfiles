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
export PATH=$HOME/.pyenv/bin:$PATH

# Claude Code background tasks
export ENABLE_BACKGROUND_TASKS=1

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/sho_yamashita/sho/Github/google-cloud-sdk/path.zsh.inc' ]; then
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'
fi
# The next line enables shell command completion for gcloud.
if [ -f '/Users/sho_yamashita/sho/Github/google-cloud-sdk/completion.zsh.inc' ]; then
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'
fi
