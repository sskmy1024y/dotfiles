## =============================
# * zplug
## =============================

source $ZPLUG_HOME/init.zsh
zplug 'zsh-users/zsh-completions'
# zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme
zplug romkatv/powerlevel10k, as:theme, depth:1
zplug 'zsh-users/zsh-syntax-highlighting', defer:2
zplug "zsh-users/zsh-autosuggestions" #履歴から予測
zplug "paulirish/git-open", as:plugin
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
# ZSH_THEME="powerlevel9k/powerlevel9k"
# POWERLEVEL9K_MODE="nerdfont-complete"
# POWERLEVEL9K_PROMPT_ADD_NEWLINE=true # 改行を追加
# POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
# POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=$'\uE0B1' # 左側矢印
# POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=$'\uE0B3' # 右側矢印
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(virtualenv ssh os_icon dir context)  # PROMPT右側
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status vcs) # PROMPT左側

# ICONS (If you see all the icons ` $ get_icon_names`)
# POWERLEVEL9K_APPLE_ICON=$'\uF302'
# POWERLEVEL9K_HOST_ICON="\uF109 "
# POWERLEVEL9K_SSH_ICON="\uF489 "
# POWERLEVEL9K_HOME_ICON="\uF015"
# POWERLEVEL9K_HOME_SUB_ICON=$'\uF07C'
# POWERLEVEL9K_FOLDER_ICON=$'\uF74A'
# POWERLEVEL9K_ETC_ICON=$'\uE799'
# POWERLEVEL9K_VCS_GIT_GITHUB_ICON=$'\uF408'

# POWERLEVEL9K_VCS_BOOKMARK_ICON=$'\uF461 '
# POWERLEVEL9K_VCS_BRANCH_ICON=$'\uF418 '
# POWERLEVEL9K_VCS_COMMIT_ICON=$'\uF417'
# POWERLEVEL9K_VCS_STASH_ICON=$'\uF48D'
# POWERLEVEL9K_VCS_STAGED_ICON=$'\uF45E'
# POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=$'\uF404 '
# POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=$'\uF403 '

# POWERLEVEL9K_DIR_HOME_BACKGROUND='036'
# POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND='038'
# POWERLEVEL9K_DIR_DEFAULT_BACKGROUND='202'
# POWERLEVEL9K_DIR_ETC_BACKGROUND='007'

# DEFAULT_USER=$USER

# POWERLEVEL9K_CONTEXT_REMOTE_FOREGROUND='041'
# POWERLEVEL9K_CONTEXT_REMOTE_SUDO_BACKGROUND='009'
# POWERLEVEL9K_CONTEXT_REMOTE_SUDO_FOREGROUND='231'

# git barnch 表示を設定
# POWERLEVEL9K_VCS_CLEAN_BACKGROUND='green'
# POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='cyan'
# POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'

zplug load
