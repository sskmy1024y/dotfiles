#!/usr/bin/env bash
# Scenario 02: Local repo, etc/install
#
# Pushes the local working copy of the dotfiles repo into the VM (so you can
# iterate on uncommitted changes) and runs the host copy of `etc/install`.
#
# This isolates installation logic from "does git work / is the URL right".
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
INSTALL_ARGS="${INSTALL_ARGS:---yes}"

step "Scenario 02: local repo, etc/install"
log "Pushing ${REPO_ROOT} -> ${TART_SSH_USER}@${VM_IP}:${REMOTE_DOTPATH}"
log "Install args: ${INSTALL_ARGS}"

vm_push_repo "$VM_IP" "$REPO_ROOT" "$REMOTE_DOTPATH"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "rsync failed (rc=${rc})"
  return "$rc" 2>/dev/null || exit "$rc"
fi

step "Running 'bash etc/install ${INSTALL_ARGS}' inside the VM"
vm_exec "$VM_IP" bash -c "'set -x; cd ${REMOTE_DOTPATH} && DOTPATH=${REMOTE_DOTPATH} bash etc/install ${INSTALL_ARGS}'"
rc=$?
if [ "$rc" -ne 0 ]; then
  error "etc/install exited with ${rc}"
  return "$rc" 2>/dev/null || exit "$rc"
fi

case " ${INSTALL_ARGS} " in
  *" --plan "*)
    step "Skipping symlink verification for plan-only run."
    rc=0
    ;;
  *)
    step "Verifying install..."
    vm_verify_install "$VM_IP"
    rc=$?
    ;;
esac

if [ "$rc" -eq 0 ]; then
  info "Scenario 02 verified."
else
  error "Scenario 02 verification failed (rc=${rc})"
fi

return "$rc" 2>/dev/null || exit "$rc"
