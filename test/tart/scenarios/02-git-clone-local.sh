#!/usr/bin/env bash
# Scenario 02: Local repo, make install
#
# Pushes the local working copy of the dotfiles repo into the VM (so you can
# iterate on uncommitted changes) and runs `make install`.
#
# This isolates installation logic from "does git work / is the URL right".
# Currently expected to fail at the tpm `git clone` step because git is not
# installed before `make deploy` runs.
#
# Sourced by tart-run; assumes VM_IP, REPO_ROOT and the helper functions are defined.

set -uo pipefail

# Use the VM's $HOME (expanded remotely) so this scenario doesn't depend on
# a specific username layout (e.g. /Users/...) — and stays portable across
# Cirrus image variants.
REMOTE_DOTPATH='$HOME/.dotfiles'

step "Scenario 02: local repo, make install"
log "Pushing ${REPO_ROOT} -> ${TART_SSH_USER}@${VM_IP}:${REMOTE_DOTPATH}"

vm_push_repo "$VM_IP" "$REPO_ROOT" "$REMOTE_DOTPATH"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "rsync failed (rc=${rc})"
  return "$rc" 2>/dev/null || exit "$rc"
fi

step "Running 'make install' inside the VM"
vm_exec "$VM_IP" bash -c "'set -x; cd ${REMOTE_DOTPATH} && make install'"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "make install exited with ${rc}"
  return "$rc" 2>/dev/null || exit "$rc"
fi

step "Verifying install..."
vm_verify_install "$VM_IP"
rc=$?

if [ "$rc" -eq 0 ]; then
  info "Scenario 02 verified."
else
  error "Scenario 02 verification failed (rc=${rc})"
fi

return "$rc" 2>/dev/null || exit "$rc"
