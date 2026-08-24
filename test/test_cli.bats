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

    mkdir -p "$DOTPATH/etc/scripts/runtimes" "$DOTPATH/etc/scripts/extras" "$DOTPATH/terraform"
    cat > "$DOTPATH/etc/install" <<'INSTALL'
#!/usr/bin/env bash
printf 'install:%s\n' "$*" >> "$CLI_MARKER"
INSTALL
    local component
    for component in anyenv node python; do
        cat > "$DOTPATH/etc/scripts/runtimes/$component.sh" <<'RUNTIME'
#!/usr/bin/env bash
printf 'runtime:%s:%s\n' "$(basename "$0" .sh)" "$*" >> "$CLI_MARKER"
RUNTIME
    done
    for component in applications cica macos; do
        cat > "$DOTPATH/etc/scripts/extras/$component.sh" <<'EXTRA'
#!/usr/bin/env bash
printf 'extra:%s:%s\n' "$(basename "$0" .sh)" "$*" >> "$CLI_MARKER"
EXTRA
    done
    chmod +x "$DOTPATH/etc/install" "$DOTPATH/etc/scripts/runtimes/"*.sh "$DOTPATH/etc/scripts/extras/"*.sh
}

teardown() {
    teardown_test_dir
}

@test "CLI help lists the supported actions" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" help

    assert_success
    assert_output --partial "dotfiles <command>"
    assert_output --partial "install"
    assert_output --partial "Apply the full setup"
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
    assert_file_contains "$CLI_MARKER" "install:--no-packages --no-macos-defaults"
}

@test "runtimes runs the explicit runtime components" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" runtimes

    assert_success
    assert_file_contains "$CLI_MARKER" "runtime:anyenv:"
    assert_file_contains "$CLI_MARKER" "runtime:node:"
    assert_file_contains "$CLI_MARKER" "runtime:python:"
}

@test "extras runs the explicit optional components" {
    run bash "$DOTFILES_SOURCE/bin/dotfiles" extras

    assert_success
    assert_file_contains "$CLI_MARKER" "extra:applications:"
    assert_file_contains "$CLI_MARKER" "extra:cica:"
    assert_file_contains "$CLI_MARKER" "extra:macos:"
}

@test "an existing Terraform state is recognized as initialized" {
    printf '{"resources":[]}\n' > "$DOTPATH/terraform/terraform.tfstate"

    run bash "$DOTFILES_SOURCE/bin/dotfiles" __is_initialized

    assert_success
}

@test "interactive menu selects an action with the down arrow" {
    skip_if_missing script
    mkdir -p "$XDG_STATE_HOME/dotfiles"
    touch "$XDG_STATE_HOME/dotfiles/installed"

    if [ "$(uname -s)" = "Darwin" ]; then
        run bash -c '(sleep 0.2; printf "\033[B\n"; sleep 0.2) | TERM=xterm-256color script -q /dev/null bash "$DOTFILES_SOURCE/bin/dotfiles"'
    else
        run bash -c '(sleep 0.2; printf "\033[B\n"; sleep 0.2) | TERM=xterm-256color script -qec "bash \"$DOTFILES_SOURCE/bin/dotfiles\"" /dev/null'
    fi

    assert_success
    assert_file_contains "$CLI_MARKER" "install:"
}

@test "interactive menu falls back to number selection on a dumb terminal" {
    skip_if_missing script
    mkdir -p "$XDG_STATE_HOME/dotfiles"
    touch "$XDG_STATE_HOME/dotfiles/installed"

    if [ "$(uname -s)" = "Darwin" ]; then
        run bash -c '(sleep 0.2; printf "2\n"; sleep 0.2) | TERM=dumb script -q /dev/null bash "$DOTFILES_SOURCE/bin/dotfiles"'
    else
        run bash -c '(sleep 0.2; printf "2\n"; sleep 0.2) | TERM=dumb script -qec "bash \"$DOTFILES_SOURCE/bin/dotfiles\"" /dev/null'
    fi

    assert_success
    assert_file_contains "$CLI_MARKER" "install:"
}
