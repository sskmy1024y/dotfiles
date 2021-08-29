## =============================
# * エイリアスなど
## =============================
alias ll='ls -l'
alias gitdir='cd ~/sho/Develop/;clear'
alias la='ls -la'

if is_exists "anyenv"; then
  eval "$(anyenv init -)"
fi
if is_exists "nodenv"; then
  eval "$(nodenv init -)"
fi

if "$(is_arm_darwin)" ; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
