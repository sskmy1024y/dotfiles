## =============================
# * ghq関連の関数
## =============================

function _ghq_select_repo() {
  if ! command -v ghq >/dev/null 2>&1; then
    echo "ghq: command not found" >&2
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf: command not found" >&2
    return 1
  fi

  local preview_cmd
  if command -v tree >/dev/null 2>&1; then
    preview_cmd='tree -N -a -C -L 2 {}'
  else
    preview_cmd='ls -la {}'
  fi

  ghq list --full-path | fzf \
    --prompt='ghq > ' \
    --height 50% \
    --reverse \
    --select-1 \
    --exit-0 \
    --query="$1" \
    --preview "$preview_cmd"
}

function ghqcd() {
  local selected_dir
  selected_dir=$(_ghq_select_repo "$1") || return

  if [ -n "$selected_dir" ]; then
    cd "$selected_dir" || return
  fi
}

function ghqcode() {
  local selected_dir
  selected_dir=$(_ghq_select_repo "$1") || return

  if [ -n "$selected_dir" ]; then
    code "$selected_dir"
  fi
}

function ghq-cd-widget() {
  local selected_dir
  selected_dir=$(_ghq_select_repo)

  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${(q)selected_dir}"
    zle accept-line
  fi

  zle clear-screen
}
zle -N ghq-cd-widget
bindkey '^]' ghq-cd-widget
