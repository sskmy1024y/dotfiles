#!/usr/bin/env bash
# tart-helpers.sh
# Shared helpers for the Tart-based macOS test environment.
#
# This file is meant to be sourced, not executed:
#   source "$(dirname "$0")/../lib/tart-helpers.sh"
#
# Conventions follow etc/lib/header.sh so the test infra feels native.

# ---- Configuration ---------------------------------------------------------

# Base image name (Cirrus Labs vanilla macOS, no extra tooling).
# Override with TART_BASE_IMAGE env var if you want a different version.
: "${TART_BASE_IMAGE:=ghcr.io/cirruslabs/macos-sequoia-vanilla:latest}"

# Local names of the long-lived "base" VM and the ephemeral test VMs.
: "${TART_BASE_VM:=dotfiles-base}"
: "${TART_TEST_VM_PREFIX:=dotfiles-test}"

# Default SSH credentials for the Cirrus Labs vanilla image.
: "${TART_SSH_USER:=admin}"
: "${TART_SSH_PASS:=admin}"

# How long (seconds) to wait for SSH to come up after `tart run`.
: "${TART_SSH_TIMEOUT:=300}"

# ---- Colors / output (match etc/lib/header.sh style) -----------------------

if [ -t 1 ] && [ -n "${TERM:-}" ] && [ "${TERM}" != "dumb" ]; then
  RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"
  YELLOW="$(printf '\033[33m')"
  BLUE="$(printf '\033[34m')"
  BOLD="$(printf '\033[1m')"
  NORMAL="$(printf '\033[0m')"
else
  RED="" GREEN="" YELLOW="" BLUE="" BOLD="" NORMAL=""
fi

info()  { echo "${GREEN}[+]${NORMAL} $*"; }
warn()  { echo "${YELLOW}[*]${NORMAL} $*"; }
error() { echo "${RED}[-]${NORMAL} $*" >&2; }
log()   { echo "    $*"; }
step()  { echo "${BLUE}${BOLD}==>${NORMAL} $*"; }

# ---- Preflight -------------------------------------------------------------

# Verify that Tart, sshpass, rsync are available.
require_tools() {
  local missing=()
  for t in tart ssh sshpass rsync; do
    if ! command -v "$t" >/dev/null 2>&1; then
      missing+=("$t")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    error "Missing required tools: ${missing[*]}"
    log "Install with:"
    log "  brew install cirruslabs/cli/tart"
    log "  brew install hudochenkov/sshpass/sshpass"
    log "  brew install rsync"
    return 1
  fi
}

# Refuse to run on non-Apple-Silicon (Tart requires Apple Silicon).
require_apple_silicon() {
  if [ "$(uname -s)" != "Darwin" ]; then
    error "Tart only runs on macOS (Apple Silicon)."
    return 1
  fi
  if [ "$(uname -m)" != "arm64" ]; then
    error "Tart requires Apple Silicon (arm64). Current arch: $(uname -m)"
    return 1
  fi
}

# ---- VM lifecycle ----------------------------------------------------------

# Return 0 if the named VM exists locally.
vm_exists() {
  local name="$1"
  tart list --format json 2>/dev/null \
    | grep -q "\"Name\"[[:space:]]*:[[:space:]]*\"${name}\""
}

# Generate a unique ephemeral VM name.
vm_unique_name() {
  echo "${TART_TEST_VM_PREFIX}-$(date +%Y%m%d-%H%M%S)-$$"
}

# Block until the VM has an IP and accepts SSH. The IP is printed on stdout
# (so callers can do `ip="$(vm_wait_ssh ...)"`); all progress messages go to
# stderr to avoid polluting the captured value.
vm_wait_ssh() {
  local name="$1"
  local deadline=$(( $(date +%s) + TART_SSH_TIMEOUT ))
  local ip=""

  step "Waiting for VM '${name}' to expose SSH (timeout: ${TART_SSH_TIMEOUT}s)..." >&2
  while [ "$(date +%s)" -lt "$deadline" ]; do
    ip="$(tart ip "$name" 2>/dev/null || true)"
    if [ -n "$ip" ]; then
      if sshpass -p "$TART_SSH_PASS" ssh \
          -o ConnectTimeout=3 \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o LogLevel=ERROR \
          "${TART_SSH_USER}@${ip}" true 2>/dev/null; then
        info "VM '${name}' is up at ${ip}" >&2
        echo "$ip"
        return 0
      fi
    fi
    sleep 3
  done

  error "Timed out waiting for VM '${name}' SSH."
  return 1
}

# Run a single command inside the VM via SSH.
# Usage: vm_exec <vm-ip> <command...>
vm_exec() {
  local ip="$1"; shift
  sshpass -p "$TART_SSH_PASS" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "${TART_SSH_USER}@${ip}" "$@"
}

# Enable passwordless sudo for the SSH user inside an ephemeral test VM.
#
# Why: the Cirrus Labs vanilla image ships with admin/admin and an interactive
# sudo prompt. Our scenarios run over a non-interactive SSH channel (no TTY),
# so anything that calls `sudo -v`, `sudoers`-gated installers, or Homebrew's
# bootstrap will hang waiting for a password. Configuring NOPASSWD here matches
# what Cirrus CI and the GitHub Actions macOS runners do out of the box.
#
# Safety: only run this against ephemeral test VMs. It writes
# /etc/sudoers.d/dotfiles-test inside the VM; the VM is destroyed at the end
# of every scenario, so no host or long-lived state is touched.
#
# Usage: vm_enable_passwordless_sudo <vm-ip>
vm_enable_passwordless_sudo() {
  local ip="$1"
  # Strategy:
  #   Stage the sudoers body in a tempfile owned by 'admin' (no sudo
  #   needed), then use `sudo -S install` to atomically promote it into
  #   /etc/sudoers.d/ as root:wheel with mode 0440.
  #
  # Why not just pipe everything into `sudo -S tee`?
  #   We tried that. On macOS the password line ended up IN the sudoers
  #   file because `sudo -S` didn't consume it from stdin in a way that
  #   hid it from the child `tee` — both lines reached tee. visudo then
  #   rejected line 1 ("admin" alone), but the second line (valid NOPASSWD)
  #   still parsed, so `sudo -n true` passed and the helper returned 0,
  #   silently leaving a broken sudoers.d/ file. Later `sudo -v` calls
  #   then re-read the file, hit the same syntax error, refused to
  #   validate, and asked for a password — which hung with no TTY.
  #
  #   Putting the body in a tempfile first means the ONLY thing on the
  #   sudo pipe is the password. There's no stdin to share with a child.
  vm_exec "$ip" bash <<EOF
set -uo pipefail

# Fast path: if \`sudo -v\` already succeeds non-interactively (image
# preconfigured by Cirrus or a previous run on the same disk), do nothing.
# Note: \`sudo -n -v\` (not \`-n true\`) — we want the exact code path the
# install scripts use, otherwise we may skip the fix and break later.
if sudo -n -v 2>/dev/null; then
  exit 0
fi

tmp=\$(mktemp /tmp/dotfiles-sudoers.XXXXXX) || {
  echo '[-] mktemp failed' >&2; exit 1;
}
trap 'rm -f "\$tmp"' EXIT
# NOPASSWD alone is not enough: macOS ships '%admin ALL=(ALL) ALL'
# (password required) in /etc/sudoers, and \`sudo -v\` will still
# prompt as long as ANY entry for this user wants a password — even
# if a NOPASSWD entry also exists. The \`Defaults:admin !authenticate\`
# line tells sudo to skip authentication entirely for user 'admin',
# which is what Cirrus CI and the GitHub Actions macOS runners do.
printf '%s\n%s\n' \\
  '${TART_SSH_USER} ALL=(ALL) NOPASSWD:ALL' \\
  'Defaults:${TART_SSH_USER} !authenticate' \\
  > "\$tmp"

# Validate before installing so a typo never produces an unrepairable
# /etc/sudoers.d state (a broken sudoers.d/ file can lock root out).
if command -v visudo >/dev/null 2>&1; then
  if ! visudo -cf "\$tmp" >/dev/null; then
    echo '[-] generated sudoers body failed visudo -cf:' >&2
    cat "\$tmp" >&2
    exit 1
  fi
fi

# Atomic promotion as root. \`install\` sets owner/group/mode in one call.
if ! printf '%s\n' '${TART_SSH_PASS}' \\
     | sudo -S -p '' install -m 440 -o root -g wheel "\$tmp" /etc/sudoers.d/dotfiles-test; then
  echo '[-] sudo -S install failed' >&2
  exit 1
fi

# Verify with \`sudo -n -v\` specifically — that is the exact code path
# the install scripts hit (\`etc/scripts/init\` runs \`sudo -v\`). \`sudo -n true\`
# would pass with just NOPASSWD; \`sudo -n -v\` only passes when no
# entry for this user requires authentication. If this fails we MUST
# fail loudly here, before the scenario hangs waiting for a TTY.
if ! sudo -n -v 2>/dev/null; then
  echo '[-] passwordless sudo did NOT take effect for \`sudo -v\`; diagnostics:' >&2
  ls -l /etc/sudoers.d/ >&2 || true
  sudo -n cat /etc/sudoers.d/dotfiles-test >&2 2>&1 || true
  exit 1
fi
EOF
}

# Push a local directory into the VM via rsync over SSH.
# Usage: vm_push <vm-ip> <local-path> <remote-path>
vm_push() {
  local ip="$1" src="$2" dst="$3"
  sshpass -p "$TART_SSH_PASS" rsync -az --delete \
    -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR" \
    "$src" "${TART_SSH_USER}@${ip}:${dst}"
}

# Push the local dotfiles repo into the VM with the standard excludes used by
# every scenario (.git, vendored Bats, this Tart harness itself).
# Usage: vm_push_repo <vm-ip> <local-repo-root> <remote-path>
vm_push_repo() {
  local ip="$1" src="$2" dst="$3"
  vm_exec "$ip" "mkdir -p '${dst}'" || return $?
  sshpass -p "$TART_SSH_PASS" rsync -az --delete \
    --exclude '.git' \
    --exclude 'test/bats' \
    --exclude 'test/tart' \
    -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR" \
    "${src%/}/" "${TART_SSH_USER}@${ip}:${dst%/}/"
}

# Verify the standard post-install state inside the VM: expected symlinks
# under $HOME, expected directories, and (with --with-brew) Homebrew on PATH.
# Returns 0 if everything is present, non-zero otherwise.
# Usage: vm_verify_install <vm-ip> [--with-brew]
vm_verify_install() {
  local ip="$1"; shift || true
  local with_brew=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --with-brew) with_brew=1 ;;
      *) error "vm_verify_install: unknown flag: $1"; return 2 ;;
    esac
    shift
  done

  vm_exec "$ip" "WITH_BREW=${with_brew} bash -s" <<'EOF'
set -uo pipefail
fail=0
for link in .zshrc .gitconfig; do
  if [ ! -L "$HOME/$link" ]; then
    echo "[-] missing or non-symlink: $HOME/$link"
    fail=1
  fi
done
for dir in .zsh .local/bin; do
  if [ ! -d "$HOME/$dir" ]; then
    echo "[-] missing directory: $HOME/$dir"
    fail=1
  fi
done
if [ "${WITH_BREW:-0}" = "1" ]; then
  if ! command -v brew >/dev/null 2>&1 \
     && ! [ -x /opt/homebrew/bin/brew ] \
     && ! [ -x /usr/local/bin/brew ]; then
    echo "[-] brew not found"
    fail=1
  fi
fi
exit $fail
EOF
}

# Stop and delete a VM. Safe to call on a non-existent VM.
vm_destroy() {
  local name="$1"
  [ -z "$name" ] && return 0
  tart stop "$name" >/dev/null 2>&1 || true
  if vm_exists "$name"; then
    tart delete "$name" >/dev/null 2>&1 || true
    info "Deleted VM '${name}'"
  fi
}

# Register a trap that destroys the VM on exit. Call once per script.
# Usage: vm_destroy_trap <vm-name>
vm_destroy_trap() {
  local name="$1"
  # shellcheck disable=SC2064
  trap "vm_destroy '${name}'" EXIT INT TERM
}

# Start a VM in the background and return its PID via stdout.
# Usage: vm_run_bg <vm-name> [extra tart-run args...]
vm_run_bg() {
  local name="$1"; shift
  # --no-graphics keeps it headless; nohup detaches from this shell.
  nohup tart run --no-graphics "$@" "$name" \
    >"/tmp/tart-${name}.log" 2>&1 &
  echo $!
}
