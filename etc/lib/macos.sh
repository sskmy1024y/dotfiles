#!/usr/bin/env bash
#
# macos.sh — Shared macOS bootstrap helpers.
#
# Sourced by install.d/* scripts that need to ensure Xcode Command Line
# Tools and Homebrew are present, without GUI prompts or duplicated logic.
#
# Conventions:
#   - All functions are idempotent (safe to call repeatedly).
#   - All functions return non-zero on hard failure; callers may decide
#     whether to abort the whole install or continue with a warning.
#   - Non-interactive by design: never spawn a GUI dialog, never block
#     waiting for user input.
#
# Requires: etc/lib/header.sh to be sourced first (for info/warn/error).

# ----------------------------------------------------------------------
# brew_prefix
#   Echo the directory that holds the brew binary on this machine, or
#   empty string if brew is not installed yet. Apple Silicon uses
#   /opt/homebrew; Intel macs use /usr/local.
# ----------------------------------------------------------------------
brew_prefix() {
  if [ -x /opt/homebrew/bin/brew ]; then
    echo /opt/homebrew
  elif [ -x /usr/local/bin/brew ]; then
    echo /usr/local
  else
    echo ""
  fi
}

# ----------------------------------------------------------------------
# brew_on_path
#   Ensure `brew` is in PATH for the *current* shell. Necessary after a
#   fresh install because the brew installer only edits ~/.zprofile.
# ----------------------------------------------------------------------
brew_on_path() {
  local prefix
  prefix="$(brew_prefix)"
  if [ -n "$prefix" ] && [ -d "$prefix/bin" ]; then
    case ":$PATH:" in
      *":$prefix/bin:"*) ;;
      *) export PATH="$prefix/bin:$PATH" ;;
    esac
  fi
}

# ----------------------------------------------------------------------
# xcode_clt_installed
#   Return 0 if Xcode Command Line Tools are usable, non-zero otherwise.
#   `xcode-select -p` printing a path is not enough — the path can exist
#   without the actual tools. We additionally probe for `git` from CLT.
# ----------------------------------------------------------------------
xcode_clt_installed() {
  local clt_path
  clt_path="$(xcode-select -p 2>/dev/null || true)"
  [ -n "$clt_path" ] && [ -d "$clt_path" ] && [ -x "$clt_path/usr/bin/git" ]
}

# ----------------------------------------------------------------------
# ensure_xcode_clt
#   Install Xcode Command Line Tools NON-INTERACTIVELY via softwareupdate.
#   The classic `xcode-select --install` opens a GUI dialog that hangs
#   automated runs. The softwareupdate trick (touch the in-progress flag,
#   then `softwareupdate --install`) avoids the GUI.
#
#   Idempotent. Returns:
#     0 — CLT now installed (or were already installed)
#     1 — installation failed; caller should warn and abort.
# ----------------------------------------------------------------------
ensure_xcode_clt() {
  if xcode_clt_installed; then
    info "Xcode Command Line Tools already installed"
    return 0
  fi

  info "Installing Xcode Command Line Tools (non-interactive)..."

  # The presence of this temp file causes `softwareupdate` to expose the
  # CLT package without a GUI prompt.
  local flag=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  touch "$flag"

  # Find the highest-versioned "Command Line Tools" product.
  local product
  product="$(softwareupdate -l 2>/dev/null \
    | awk -F'\\*' '/\* (Label|Command Line Tools)/ { print $2 }' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | grep -E '^(Label: )?Command Line Tools' \
    | sed -e 's/^Label: //' \
    | sort -V \
    | tail -n 1)"

  if [ -z "$product" ]; then
    rm -f "$flag"
    error "softwareupdate did not list a Command Line Tools product."
    error "Manual fallback: run 'xcode-select --install' once interactively."
    return 1
  fi

  info "Installing: ${product}"
  # softwareupdate -i must run as root. We rely on the caller having either
  # passwordless sudo (CI / the Tart test harness configures this) or an
  # already-cached sudo timestamp; either way, prompting here would hang a
  # non-interactive install.
  if ! sudo -n softwareupdate -i "$product" --verbose; then
    rm -f "$flag"
    error "softwareupdate failed to install '${product}'"
    error "Hint: ensure passwordless sudo is configured or run 'sudo -v' first."
    return 1
  fi
  rm -f "$flag"

  if ! xcode_clt_installed; then
    error "Command Line Tools install reported success but tools not usable"
    return 1
  fi

  info "Xcode Command Line Tools installed."
}

# ----------------------------------------------------------------------
# ensure_homebrew
#   Bootstrap Homebrew if not already installed. Idempotent.
#   After this returns 0, `brew` is guaranteed to be on PATH for the
#   current shell.
#
#   Returns:
#     0 — brew is installed and on PATH
#     1 — bootstrap failed
# ----------------------------------------------------------------------
ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    info "Homebrew already installed: $(command -v brew)"
    return 0
  fi

  # Maybe brew is installed but not on PATH (e.g. fresh `make init`).
  brew_on_path
  if command -v brew >/dev/null 2>&1; then
    info "Homebrew found at $(command -v brew) (added to PATH)"
    return 0
  fi

  info "Installing Homebrew..."
  # NONINTERACTIVE=1 skips the "Press RETURN" prompt — required for CI/Tart.
  if ! NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    error "Homebrew bootstrap failed."
    return 1
  fi

  brew_on_path
  if ! command -v brew >/dev/null 2>&1; then
    error "Homebrew installed but 'brew' is still not on PATH."
    return 1
  fi

  info "Homebrew installed: $(command -v brew)"
}
