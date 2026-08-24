#!/bin/sh

# POSIX entrypoint for: curl -fsSL <url>/install.sh | sh

set -eu

: "${DOTFILES_BRANCH:=master}"
: "${DOTFILES_INSTALL_BASE_URL:=https://raw.githubusercontent.com/sskmy1024y/dotfiles}"

bootstrap_url="${DOTFILES_INSTALL_BASE_URL}/${DOTFILES_BRANCH}/etc/bootstrap"
tmp_dir="$(mktemp -d)"
bootstrap="$tmp_dir/bootstrap"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$bootstrap_url" -o "$bootstrap"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$bootstrap" "$bootstrap_url"
else
  echo "[-] curl or wget is required to install dotfiles" >&2
  exit 1
fi

if ! command -v bash >/dev/null 2>&1; then
  echo "[-] bash is required to install dotfiles" >&2
  exit 1
fi

# A pipe owns stdin in `curl ... | sh`. Give prompts and sudo the terminal
# when one is available; non-interactive environments keep their original stdin.
if [ -r /dev/tty ] && [ -w /dev/tty ]; then
  bash "$bootstrap" "$@" </dev/tty
else
  bash "$bootstrap" "$@"
fi
