#!/usr/bin/env bats

# Tests for the dotfiles command-line interface.

load test_helper

setup() {
    setup_test_dir
    export DOTFILES_SOURCE="$DOTPATH"
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$HOME/.dotfiles"
    export XDG_STATE_HOME="$HOME/.local/state"
    export CLI_MARKER="$TEST_TEMP_DIR/cli-marker"

    mkdir -p "$DOTPATH/etc/scripts/deep.d" "$DOTPATH/terraform"
    cat > "$DOTPATH/etc/install" <<'INSTALL'
#!/usr/bin/env bash
printf 'install:%s\n' "$*" >> "$CLI_MARKER"
INSTALL
    cat > "$DOTPATH/etc/scripts/init" <<'RUNTIMES'
#!/usr/bin/env bash
printf 'runtimes:%s\n' "$*" >> "$CLI_MARKER"
RUNTIMES
    chmod +x "$DOTPATH/etc/install" "$DOTPATH/etc/scripts/init"
}

teardown() {
    teardown_test_dir
}

@test "CLI help lists the supported actions" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" help

    assert_success
    assert_output --partial "dotfiles <command>"
    assert_output --partial "install"
    assert_output --partial "sync"
    assert_output --partial "runtimes"
}

@test "install delegates to the installer and records successful setup" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" install --yes

    assert_success
    assert_file_contains "$CLI_MARKER" "install:--yes"
    assert_file_exists "$XDG_STATE_HOME/dotfiles/installed"
}

@test "check does not record a completed installation" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" install --check

    assert_success
    assert_file_contains "$CLI_MARKER" "install:--check"
    assert_not_exists "$XDG_STATE_HOME/dotfiles/installed"
}

@test "sync disables package and macOS settings" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" sync

    assert_success
    assert_file_contains "$CLI_MARKER" "install:--no-brew --no-macos-defaults"
}

@test "runtimes delegates to the optional runtime installer" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" runtimes

    assert_success
    assert_file_contains "$CLI_MARKER" "runtimes:"
}

@test "an existing Terraform state is recognized as initialized" {
    printf '{"resources":[]}\n' > "$DOTPATH/terraform/terraform.tfstate"

    run bash "$DOTFILES_SOURCE/bin/dotfiles" __is_initialized

    assert_success
}
