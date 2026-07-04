## =============================
# * gcloud関連の関数
## =============================

function _gcloud_select_configuration() {
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "gcloud: command not found" >&2
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf: command not found" >&2
    return 1
  fi

  local -a fzf_opts
  fzf_opts=(
    --prompt='gcloud config > '
    --height 50%
    --reverse
    --query="$1"
    --header=$'ACTIVE\tNAME\tACCOUNT\tPROJECT'
    --delimiter=$'\t'
    --preview='gcloud --configuration {2} config list 2>/dev/null'
  )

  # 第2引数に "interactive" を渡した場合は、
  #   - 候補が1つでも自動選択しない (--select-1 を付けない)
  #   - 候補が0件でも fzf を閉じず、空の状態で表示する (--exit-0 を付けない)
  if [ "$2" != "interactive" ]; then
    fzf_opts+=(--select-1 --exit-0)
  fi

  gcloud config configurations list --format='value(is_active.yesno(yes="[x]",no="[_]"),name,properties.core.account,properties.core.project)' \
    | awk 'BEGIN { FS = OFS = "\t" } { print $1, $2, ($3 == "" ? "(unset)" : $3), ($4 == "" ? "(unset)" : $4) }' \
    | fzf "${fzf_opts[@]}" \
    | awk 'BEGIN { FS = "\t" } { print $2 }'
}

function _gcloud_config_catalog_path() {
  echo "${GCLOUD_CONFIG_CATALOG:-${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/configurations.tsv}"
}

function _gcloud_catalog_rows() {
  local catalog
  catalog=$(_gcloud_config_catalog_path)

  if [ ! -f "$catalog" ]; then
    echo "gcloud config catalog not found: $catalog" >&2
    echo "Create it as TSV: name<TAB>account<TAB>project" >&2
    return 1
  fi

  awk '
    BEGIN { FS = OFS = "\t" }
    /^[[:space:]]*($|#)/ { next }
    NF >= 3 { print $1, $2, $3 }
  ' "$catalog"
}

function _gcloud_apply_catalog_configuration() {
  local name="$1"
  local account="$2"
  local project="$3"
  local activate="${4:-activate}"

  if [ -z "$name" ] || [ -z "$project" ]; then
    echo "usage: _gcloud_apply_catalog_configuration <name> <account> <project> [activate|no-activate]" >&2
    return 1
  fi

  if ! gcloud config configurations list --format='value(name)' | grep -Fxq "$name"; then
    gcloud config configurations create "$name" --no-activate
  fi

  if [ -n "$account" ] && [ "$account" != "(unset)" ]; then
    gcloud --configuration "$name" config set account "$account"
  fi

  gcloud --configuration "$name" config set project "$project"

  if [ "$activate" != "no-activate" ]; then
    gcloud config configurations activate "$name"
  fi
}

function _gcloud_get_config_value() {
  local value
  value=$(gcloud config get-value "$1" 2>/dev/null) || return 1

  if [ "$value" = "(unset)" ]; then
    value=""
  fi

  echo "$value"
}

function _gcloud_confirm() {
  local prompt="$1"
  local answer

  if [ ! -t 0 ]; then
    return 1
  fi

  read "answer?${prompt} [Y/n] "
  case "$answer" in
    [nN]|[nN][oO])
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

function _gcloud_has_auth_account() {
  local account="$1"

  [ -n "$account" ] || return 1

  gcloud auth list --filter-account="$account" --format='value(account)' 2>/dev/null \
    | grep -Fxq "$account"
}

function _gcloud_ensure_auth_account() {
  local account="$1"

  if _gcloud_has_auth_account "$account"; then
    return 0
  fi

  if [ ! -t 0 ]; then
    echo "gcloud auth credentials not found for: $account" >&2
    echo "Run manually: gcloud auth login $account" >&2
    return 1
  fi

  if _gcloud_confirm "gcloud auth credentials not found for $account. Run gcloud auth login?"; then
    gcloud auth login "$account"
    return $?
  fi

  return 1
}

function _gcloud_update_adc_after_switch() {
  local previous_account="$1"
  local current_account="$2"
  local current_project="$3"

  if [ -z "$current_project" ]; then
    return
  fi

  if [ "$previous_account" = "$current_account" ]; then
    if ! gcloud auth application-default set-quota-project "$current_project"; then
      echo "failed to update application-default quota project: $current_project" >&2
    fi
    return
  fi

  if [ -z "$current_account" ]; then
    echo "gcloud account is unset; skip application-default login" >&2
    return
  fi

  if [ ! -t 0 ]; then
    echo "gcloud account changed: ${previous_account:-"(unset)"} -> $current_account" >&2
    if ! _gcloud_has_auth_account "$current_account"; then
      echo "Run manually: gcloud auth login $current_account" >&2
    fi
    echo "Run manually: gcloud auth application-default login $current_account" >&2
    return
  fi

  echo "gcloud account changed: ${previous_account:-"(unset)"} -> $current_account" >&2
  _gcloud_ensure_auth_account "$current_account" || return

  if _gcloud_confirm "Run gcloud auth application-default login for $current_account?"; then
    gcloud auth application-default login "$current_account"
  fi
}

function _gcloud_activate_configuration() {
  local selected="$1"
  local previous_account current_account current_project

  if [ -z "$selected" ]; then
    return
  fi

  previous_account=$(_gcloud_get_config_value account)
  gcloud config configurations activate "$selected"
  current_account=$(_gcloud_get_config_value account)
  current_project=$(_gcloud_get_config_value project)

  _gcloud_update_adc_after_switch "$previous_account" "$current_account" "$current_project"
}

# gcloud config configurationsの一覧から選択してactivateする
function gcloud-switch() {
  local selected
  selected=$(_gcloud_select_configuration "$1") || return

  if [ -n "$selected" ]; then
    _gcloud_activate_configuration "$selected"
  fi
}

function gcloud-config-sync() {
  local row name account project

  _gcloud_catalog_rows | while IFS=$'\t' read -r name account project; do
    [ -n "$name" ] || continue
    _gcloud_apply_catalog_configuration "$name" "$account" "$project" no-activate
  done
}

function gcloud-switch-widget() {
  local selected
  selected=$(_gcloud_select_configuration "" interactive)

  if [ -n "$selected" ]; then
    _gcloud_activate_configuration "$selected"
    zle reset-prompt
  fi

  zle clear-screen
}
zle -N gcloud-switch-widget

alias gx='gcloud-switch'
