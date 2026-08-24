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

if [ "${1:-}" = "--version" ]; then
  echo "git version 2.0.0"
  exit 0
fi

last=""
for arg in "$@"; do
  last="$arg"
done

mkdir -p "$last/etc"
    cat > "$last/etc/install" <<'INSTALL'
#!/usr/bin/env bash
printf 'install:%s\n' "$*" > "$BOOTSTRAP_MARKER"
printf 'branch:%s\n' "${DOTFILES_BRANCH:-}" >> "$BOOTSTRAP_MARKER"
INSTALL
EOF
    chmod +x "$mock_dir/git"
    export PATH="$mock_dir:$PATH"
}

@test "bootstrap clones requested branch and delegates to install" {
    write_mock_git_clone

    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$TEST_TEMP_DIR/home/.dotfiles"
    export DOTFILES_GITHUB="https://github.com/example/dotfiles.git"
    export DOTFILES_BRANCH="feature/bootstrap"
    export BOOTSTRAP_MARKER="$TEST_TEMP_DIR/marker"

    run bash "$DOTPATH_SOURCE/etc/bootstrap" --check

    assert_success
    assert_file_exists "$DOTPATH/etc/install"
    assert_file_exists "$BOOTSTRAP_MARKER"
    assert_file_contains "$BOOTSTRAP_MARKER" "install:--check"
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
    cat > "$DOTPATH/etc/install" <<'INSTALL'
#!/usr/bin/env bash
printf 'existing:%s\n' "$*" > "$BOOTSTRAP_MARKER"
INSTALL

    run bash "$DOTPATH_SOURCE/etc/bootstrap" --check

    assert_success
    assert_file_contains "$BOOTSTRAP_MARKER" "existing:--check"
}

@test "bootstrap uses a tarball when git exists but is not functional" {
    local mock_dir="$TEST_TEMP_DIR/mocks"
    local fixture_dir="$TEST_TEMP_DIR/dotfiles-feature-bootstrap"
    local fixture_archive="$TEST_TEMP_DIR/dotfiles.tar.gz"
    mkdir -p "$mock_dir" "$fixture_dir/etc"

    cat > "$mock_dir/git" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
    cat > "$mock_dir/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    output="$2"
    shift 2
  else
    shift
  fi
done
cp "$BOOTSTRAP_FIXTURE" "$output"
EOF
    cat > "$fixture_dir/etc/install" <<'EOF'
#!/usr/bin/env bash
printf 'archive:%s\n' "$*" > "$BOOTSTRAP_MARKER"
EOF
    chmod +x "$mock_dir/git" "$mock_dir/curl" "$fixture_dir/etc/install"
    tar -czf "$fixture_archive" -C "$TEST_TEMP_DIR" "$(basename "$fixture_dir")"

    export PATH="$mock_dir:$PATH"
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$TEST_TEMP_DIR/home/.dotfiles"
    export DOTFILES_ARCHIVE_URL="https://example.invalid/dotfiles.tar.gz"
    export BOOTSTRAP_FIXTURE="$fixture_archive"
    export BOOTSTRAP_MARKER="$TEST_TEMP_DIR/marker"

    run bash "$DOTPATH_SOURCE/etc/bootstrap" --check

    assert_success
    assert_file_exists "$DOTPATH/etc/install"
    assert_file_contains "$BOOTSTRAP_MARKER" "archive:--check"
    assert_output --partial "Git is not available"
}

@test "bootstrap routes commands through the installed CLI" {
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$HOME/.dotfiles"
    export BOOTSTRAP_MARKER="$TEST_TEMP_DIR/marker"
    mkdir -p "$DOTPATH/etc" "$DOTPATH/bin"
    touch "$DOTPATH/etc/install"
    cat > "$DOTPATH/bin/dotfiles" <<'CLI'
#!/usr/bin/env bash
printf 'cli:%s\n' "$*" > "$BOOTSTRAP_MARKER"
CLI

    run bash "$DOTPATH_SOURCE/etc/bootstrap" check

    assert_success
    assert_file_contains "$BOOTSTRAP_MARKER" "cli:check"
    assert_symlink_to "$DOTPATH/bin/dotfiles" "$HOME/.local/bin/dotfiles"
}

@test "POSIX install entrypoint downloads bootstrap and forwards arguments" {
    local fixture_root="$TEST_TEMP_DIR/remote"
    mkdir -p "$fixture_root/master/etc"
    cat > "$fixture_root/master/etc/bootstrap" <<'BOOTSTRAP'
#!/usr/bin/env bash
printf 'launcher:%s\n' "$*" > "$BOOTSTRAP_MARKER"
BOOTSTRAP
    export BOOTSTRAP_MARKER="$TEST_TEMP_DIR/marker"
    export DOTFILES_INSTALL_BASE_URL="file://$fixture_root"

    run sh "$DOTPATH_SOURCE/install.sh" check

    assert_success
    assert_file_contains "$BOOTSTRAP_MARKER" "launcher:check"
}
