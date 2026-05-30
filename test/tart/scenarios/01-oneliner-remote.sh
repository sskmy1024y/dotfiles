#!/usr/bin/env bash
# Scenario 01: Remote curl one-liner
#
# Reproduces the install method documented in README:
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup)"
#
# This is the WORST-CASE entrypoint: a brand-new macOS user types this and
# expects everything to bootstrap. Currently expected to fail until the
# install scripts are fixed.
#
# Sourced by tart-run; assumes VM_IP and the helper functions are defined.

# These scripts are dual-mode (sourced OR executed standalone), so each error
# branch ends with `return … 2>/dev/null || exit …`. ShellCheck flags the
# `exit` half as unreachable, which it isn't when the script is executed.
# shellcheck disable=SC2317
set -uo pipefail

ONELINER_URL="${ONELINER_URL:-https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup}"

step "Scenario 01: remote curl one-liner"
log "URL: ${ONELINER_URL}"

# Run the one-liner exactly as a user would.
vm_exec "$VM_IP" bash -c "'set -x; bash -c \"\$(curl -fsSL ${ONELINER_URL})\"'"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "Remote one-liner exited with ${rc}"
  return "$rc" 2>/dev/null || exit "$rc"
fi

step "Verifying install..."
vm_verify_install "$VM_IP"
rc=$?

if [ "$rc" -eq 0 ]; then
  info "Scenario 01 verified: install landed."
else
  error "Scenario 01 verification failed (rc=${rc})"
fi

return "$rc" 2>/dev/null || exit "$rc"
