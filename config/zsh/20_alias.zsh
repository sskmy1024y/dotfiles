## =============================
# * エイリアス
## =============================
alias ll='ls -l'
alias la='ls -la'

## =============================
# * Homebrew
## =============================
if "$(is_arm_darwin)"; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

## =============================
# * バージョンマネージャ (mise)
## =============================
# node / python / pnpm などは mise で管理する (config/mise/config.toml)。
#   - macOS は Homebrew、Linux は ~/.local/bin に mise.run で導入される。
#   - activate はプロンプト毎に hook-env を実行し、.node-version 等に追従して PATH を切り替える。
if is_exists "mise"; then
  eval "$(mise activate zsh)"
fi

## =============================
# * その他ツール
## =============================
if is_exists "github-copilot-cli"; then
  eval "$(github-copilot-cli alias -- "$0")"
fi
