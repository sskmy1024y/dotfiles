#!/usr/bin/env bash
# Scenario 03: Full Terraform install
#
# Pushes the local working copy and runs the host copy of `etc/install --yes`
# with the default module set. This is the most thorough Terraform installer
# test and does not require the branch to be pushed.
#
# Sourced by tart-run; assumes VM_IP, REPO_ROOT and the helper functions are defined.

# These scripts are dual-mode (sourced OR executed standalone), so each error
# branch ends with `return … 2>/dev/null || exit …`. ShellCheck flags the
# `exit` half as unreachable, which it isn't when the script is executed.
# shellcheck disable=SC2317
set -uo pipefail

# tart-run resolves the VM's $HOME at boot and exports it as REMOTE_HOME, so
# we can build an unambiguous absolute path here. (Embedding a literal
# '$HOME' is unsafe: rsync treats it as a literal directory name, while a
# remote `bash -c 'cd $HOME/...'` expands it — the two end up out of sync.)
REMOTE_DOTPATH="${REMOTE_HOME}/.dotfiles"

step "Scenario 03: full Terraform install"
log "Pushing ${REPO_ROOT} -> ${TART_SSH_USER}@${VM_IP}:${REMOTE_DOTPATH}"

vm_push_repo "$VM_IP" "$REPO_ROOT" "$REMOTE_DOTPATH"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "rsync failed (rc=${rc})"
  return "$rc" 2>/dev/null || exit "$rc"
fi

step "Running 'bash etc/install --yes' inside the VM"
vm_exec "$VM_IP" bash -c "'set -x; cd ${REMOTE_DOTPATH} && DOTPATH=${REMOTE_DOTPATH} bash etc/install --yes'"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "etc/install --yes exited with ${rc}"
  return "$rc" 2>/dev/null || exit "$rc"
fi

step "Verifying install..."
vm_verify_install "$VM_IP" --with-brew
rc=$?

if [ "$rc" -eq 0 ]; then
  info "Scenario 03 verified: full Terraform install succeeded."
else
  error "Scenario 03 verification failed (rc=${rc})"
fi

return "$rc" 2>/dev/null || exit "$rc"
