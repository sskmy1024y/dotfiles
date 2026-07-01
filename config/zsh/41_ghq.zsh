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

  local -a fzf_opts
  fzf_opts=(
    --prompt='ghq > '
    --height 50%
    --reverse
    --query="$1"
    --preview "$preview_cmd"
    # 表示・検索は末尾2フィールド(user/repo)だけにする。
    # 選択結果や preview の {} は元の行(full path)のままなので cd はそのまま動く。
    --delimiter /
    --with-nth -2..
  )

  # 第2引数に "interactive" を渡した場合は、
  #   - 候補が1つでも自動選択しない (--select-1 を付けない)
  #   - 候補が0件でも fzf を閉じず、空の状態で表示する (--exit-0 を付けない)
  if [ "$2" != "interactive" ]; then
    fzf_opts+=(--select-1 --exit-0)
  fi

  ghq list --full-path | fzf "${fzf_opts[@]}"
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
  selected_dir=$(_ghq_select_repo "" interactive)

  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${(q)selected_dir}"
    zle accept-line
  fi

  zle clear-screen
}
zle -N ghq-cd-widget
bindkey '^]' ghq-cd-widget
