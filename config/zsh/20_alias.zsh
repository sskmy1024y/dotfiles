## =============================
# * エイリアスなど
## =============================
alias ll='ls -l'
alias gitdir='cd ~/sho/Develop/;clear'
alias la='ls -la'

# anyenv
if is_exists "anyenv"; then
   if ! [ -f /tmp/anyenv.cache ]; then
      anyenv init - --no-rehash > /tmp/anyenv.cache
      zcompile /tmp/anyenv.cache
   fi
   source /tmp/anyenv.cache
fi

if is_exists "nodenv"; then
   if ! [ -f /tmp/nodenv.cache ]; then
      nodenv init - > /tmp/nodenv.cache
      zcompile /tmp/nodenv.cache
   fi
   source /tmp/nodenv.cache
fi

if is_exists "pyenv"; then
   if ! [ -f /tmp/pyenv.cache ]; then
      pyenv init - > /tmp/pyenv.cache
      zcompile /tmp/pyenv.cache
   fi
   source /tmp/pyenv.cache
fi

if "$(is_arm_darwin)" ; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
