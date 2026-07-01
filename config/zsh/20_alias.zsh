## =============================
# * エイリアス
## =============================
alias ll='ls -l'
alias la='ls -la'

## =============================
# * バージョンマネージャ (anyenv: nodenv/pyenv/goenv/rbenv/jenv)
## =============================
# 起動高速化のため遅延ロードする。
#   - anyenv 本体と各 env の shims を PATH に追加する (下のループ)。
#     → python / node / go / ruby / java は init 無しでも解決できる。
#   - 重い `anyenv init -` (関数定義・補完・rehash) は *env コマンド初回実行まで遅延。
#   - anyenv init が 5 env 全ての初期化を出力するため個別 init は不要 (二重初期化を解消)。
#   - `--no-rehash` で起動時の rehash fork を排除 (rehash は新バージョン導入時に自動実行)。

# pyenv install が macOS で余計な Framework / Tk をビルドしないようにする
if [ "$(detect_os)" = "darwin" ]; then
  export PYTHON_CONFIGURE_OPTS="--enable-framework=no --disable-tk"
fi

if [ -d "$HOME/.anyenv" ]; then
  # anyenv 本体と各 env の shims を PATH に追加する。
  # shims が PATH にあれば、init 前でも python / node 等のコマンドが解決できる。
  export PATH="$HOME/.anyenv/bin:$PATH"
  for _env_dir in "$HOME"/.anyenv/envs/*(N/); do
    export PATH="$_env_dir/shims:$PATH"
  done
  unset _env_dir

  # 初回の *env 呼び出し時に一度だけ本物の init を読み込む
  _anyenv_lazy_load() {
    unset -f anyenv goenv jenv nodenv pyenv rbenv 2>/dev/null

    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    local cache="$cache_dir/anyenv-init.zsh"

    # env の追加/削除 (envs ディレクトリの mtime 更新) を検知してキャッシュを作り直す
    if [[ ! -e "$cache" || "$HOME/.anyenv/envs" -nt "$cache" ]]; then
      mkdir -p "$cache_dir"
      anyenv init - --no-rehash > "$cache"
      zcompile "$cache" 2>/dev/null
    fi

    source "$cache"
  }

  # 各 *env を「初回だけ本物を読み込んで委譲する」スタブ関数に置き換える。
  #   例: pyenv() { _anyenv_lazy_load; pyenv "$@" }
  for _env in anyenv goenv jenv nodenv pyenv rbenv; do
    functions[$_env]="_anyenv_lazy_load; $_env \"\$@\""
  done
  unset _env
fi

## =============================
# * Homebrew
## =============================
if "$(is_arm_darwin)"; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

## =============================
# * その他ツール
## =============================
if is_exists "github-copilot-cli"; then
  eval "$(github-copilot-cli alias -- "$0")"
fi
