#!/usr/bin/env bats

# Tests for etc/bootstrap: the remote one-liner entrypoint.

load test_helper

setup() {
    setup_test_dir
    export DOTPATH_SOURCE="$DOTPATH"
}

teardown() {
    teardown_test_dir
}

write_mock_git_clone() {
    local mock_dir="$TEST_TEMP_DIR/mocks"
    mkdir -p "$mock_dir"
    cat > "$mock_dir/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

last=""
for arg in "$@"; do
  last="$arg"
done

mkdir -p "$last/etc"
cat > "$last/etc/setup" <<'SETUP'
#!/usr/bin/env bash
printf 'setup:%s\n' "$*" > "$BOOTSTRAP_MARKER"
printf 'branch:%s\n' "${DOTFILES_BRANCH:-}" >> "$BOOTSTRAP_MARKER"
SETUP
EOF
    chmod +x "$mock_dir/git"
    export PATH="$mock_dir:$PATH"
}

@test "bootstrap clones requested branch and delegates to setup" {
    write_mock_git_clone

    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$TEST_TEMP_DIR/home/.dotfiles"
    export DOTFILES_GITHUB="https://github.com/example/dotfiles.git"
    export DOTFILES_BRANCH="feature/bootstrap"
    export BOOTSTRAP_MARKER="$TEST_TEMP_DIR/marker"

    run bash "$DOTPATH_SOURCE/etc/bootstrap" init

    assert_success
    assert_file_exists "$DOTPATH/etc/setup"
    assert_file_exists "$BOOTSTRAP_MARKER"
    assert_file_contains "$BOOTSTRAP_MARKER" "setup:init"
    assert_file_contains "$BOOTSTRAP_MARKER" "branch:feature/bootstrap"
}

@test "bootstrap delegates to existing checkout without cloning" {
    local mock_dir="$TEST_TEMP_DIR/mocks"
    mkdir -p "$mock_dir"
    cat > "$mock_dir/git" <<'EOF'
#!/usr/bin/env bash
echo "git should not be called" >&2
exit 1
EOF
    chmod +x "$mock_dir/git"
    export PATH="$mock_dir:$PATH"

    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$TEST_TEMP_DIR/home/.dotfiles"
    export BOOTSTRAP_MARKER="$TEST_TEMP_DIR/marker"
    mkdir -p "$DOTPATH/etc"
    cat > "$DOTPATH/etc/setup" <<'SETUP'
#!/usr/bin/env bash
printf 'existing:%s\n' "$*" > "$BOOTSTRAP_MARKER"
SETUP

    run bash "$DOTPATH_SOURCE/etc/bootstrap" deploy

    assert_success
    assert_file_contains "$BOOTSTRAP_MARKER" "existing:deploy"
}
