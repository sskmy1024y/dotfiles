#!/usr/bin/env bats

# Integration tests for the legacy deploy script.

bats_require_minimum_version 1.5.0

load test_helper

setup() {
    setup_test_dir
    export HOME="$TEST_TEMP_DIR/home"
    export DOTFILES_GHOSTTY_INSTALLED=0
    mkdir -p "$HOME"
}

teardown() {
    teardown_test_dir
}

@test "deploy creates the managed directory and symlink tree" {
    export DOTFILES_OS_OVERRIDE="darwin"

    run bash "$DOTPATH/etc/scripts/deploy"

    assert_success
    assert_dir_exists "$HOME/.local/bin"
    assert_dir_exists "$HOME/.zsh"
    assert_dir_exists "$HOME/.git_template/hooks"
    assert_link_exists "$HOME/.zshrc"
    assert_symlink_to "$DOTPATH/config/zsh/.zshrc" "$HOME/.zshrc"
    assert_symlink_to "$DOTPATH/config/git/.gitconfig" "$HOME/.gitconfig"
    assert_symlink_to "$DOTPATH/config/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    assert_symlink_to "$DOTPATH/bin/dotfiles" "$HOME/.local/bin/dotfiles"
    assert_symlink_to "$DOTPATH/config/ssh/config" "$HOME/.ssh/config"
    assert_symlink_to "$DOTPATH/config/ssh/git.conf" "$HOME/.ssh/git.conf"
    assert_symlink_to "$DOTPATH/config/ssh/1password.conf" "$HOME/.ssh/1password.conf"
    run get_permissions "$HOME/.ssh"
    assert_output "700"
    run get_permissions "$HOME/.ssh/authorized_keys"
    assert_output "600"
}

@test "deploy preserves regular files and is idempotent" {
    export DOTFILES_OS_OVERRIDE="darwin"
    create_test_file "$HOME/.zshrc" "existing zshrc"
    create_test_file "$HOME/.gitconfig" "existing gitconfig"

    run bash "$DOTPATH/etc/scripts/deploy"
    assert_success
    local first_symlink_count
    first_symlink_count="$(count_symlinks "$HOME")"

    run bash "$DOTPATH/etc/scripts/deploy"
    assert_success
    assert_equal "$(count_symlinks "$HOME")" "$first_symlink_count"
    assert_not_link_exists "$HOME/.zshrc"
    assert_not_link_exists "$HOME/.gitconfig"
    assert_file_contains "$HOME/.zshrc" "existing zshrc"
    assert_file_contains "$HOME/.gitconfig" "existing gitconfig"
}

@test "deploy does not generate local SSH keys on macOS" {
    export DOTFILES_OS_OVERRIDE="darwin"
    mock_command "ssh-keygen" 'echo "ssh-keygen should not be called" >&2; exit 42'

    run bash "$DOTPATH/etc/scripts/deploy"

    assert_success
    assert_not_exists "$HOME/.ssh/github-key"
    assert_not_exists "$HOME/.ssh/github-key.pub"
}

@test "deploy generates local SSH keys on Linux" {
    export DOTFILES_OS_OVERRIDE="ubuntu"
    mock_command "ssh-keygen" '
if [[ "$1" == "-q" && "$2" == "-f" ]]; then
  touch "$3" "$3.pub"
  exit 0
fi
exit 42
'

    run bash "$DOTPATH/etc/scripts/deploy"

    assert_success
    assert_file_exists "$HOME/.ssh/github-key"
    assert_file_exists "$HOME/.ssh/github-key.pub"
    assert_not_exists "$HOME/.ssh/1password.conf"
}

@test "deploy defaults DOTPATH to the checkout under HOME" {
    ln -s "$DOTPATH" "$HOME/.dotfiles"

    run env -u DOTPATH HOME="$HOME" DOTFILES_OS_OVERRIDE=darwin \
        DOTFILES_GHOSTTY_INSTALLED=0 bash "$HOME/.dotfiles/etc/scripts/deploy"

    assert_success
    assert_symlink_to "$HOME/.dotfiles/config/zsh/.zshrc" "$HOME/.zshrc"
}
