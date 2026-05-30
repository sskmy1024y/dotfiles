#!/usr/bin/env bash
# Scenario 03: Full install (deploy + init + deep)
#
# Like scenario 02 but runs each phase separately and also requires `make deep`
# (advanced tools and fonts) to succeed. This is the most thorough test.
#
# Sourced by tart-run; assumes VM_IP, REPO_ROOT and the helper functions are defined.

set -uo pipefail

# Use the VM's $HOME (expanded remotely) so this scenario doesn't depend on
# a specific username layout (e.g. /Users/...) — and stays portable across
# Cirrus image variants.
REMOTE_DOTPATH='$HOME/.dotfiles'

step "Scenario 03: full install (deploy + init + deep)"
log "Pushing ${REPO_ROOT} -> ${TART_SSH_USER}@${VM_IP}:${REMOTE_DOTPATH}"

vm_push_repo "$VM_IP" "$REPO_ROOT" "$REMOTE_DOTPATH"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "rsync failed (rc=${rc})"
  return "$rc" 2>/dev/null || exit "$rc"
fi

# Run each phase separately so we can see exactly where it falls over.
for phase in deploy init deep; do
  step "make ${phase}"
  vm_exec "$VM_IP" bash -c "'set -x; cd ${REMOTE_DOTPATH} && make ${phase}'"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    error "make ${phase} exited with ${rc}"
    return "$rc" 2>/dev/null || exit "$rc"
  fi
done

step "Verifying install..."
vm_verify_install "$VM_IP" --with-brew
rc=$?

if [ "$rc" -eq 0 ]; then
  info "Scenario 03 verified: full install succeeded."
else
  error "Scenario 03 verification failed (rc=${rc})"
fi

return "$rc" 2>/dev/null || exit "$rc"
