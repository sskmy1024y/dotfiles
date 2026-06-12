#!/usr/bin/env bats

# Test for etc/lib/macos.sh — Xcode CLT + Homebrew bootstrap helpers.
#
# These tests focus on the pure functions (brew_prefix, brew_on_path,
# xcode_clt_installed) and on the idempotency-skip path of the
# ensure_* functions. We never invoke a real CLT/brew install from
# tests — that path is exercised by the Tart scenarios in test/tart/.

load test_helper

setup() {
    setup_test_dir
    # Load the lib under test. header.sh is already loaded by test_helper.
    source "$DOTPATH/etc/lib/macos.sh"
}

teardown() {
    teardown_test_dir
}

# ---- brew_prefix -----------------------------------------------------

@test "brew_prefix is one of /opt/homebrew, /usr/local, or empty" {
    run brew_prefix
    assert_success
    case "$output" in
        ""|/opt/homebrew|/usr/local)
            :
            ;;
        *)
            fail "brew_prefix returned unexpected value: $output"
            ;;
    esac
}

@test "brew_prefix is non-empty when brew is installed" {
    skip_if_missing brew
    run brew_prefix
    assert_success
    assert [ -n "$output" ]
}

# ---- brew_on_path ----------------------------------------------------

@test "brew_on_path is a no-op when brew is not installed" {
    if [ -n "$(brew_prefix)" ]; then
        skip "brew is installed; this test only covers the no-op path"
    fi
    local before="$PATH"
    run brew_on_path
    assert_success
    # PATH should be unchanged.
    assert_equal "$PATH" "$before"
}

@test "brew_on_path puts brew on PATH when installed" {
    skip_if_missing brew
    # Strip brew dir from PATH so we can verify it gets put back.
    local prefix
    prefix="$(brew_prefix)"
    [ -n "$prefix" ] || skip "no brew prefix detected"

    local stripped
    stripped="$(echo "$PATH" | tr ':' '\n' | grep -vx "$prefix/bin" | paste -sd: -)"
    export PATH="$stripped"

    brew_on_path
    case ":$PATH:" in
        *":$prefix/bin:"*) : ;;
        *) fail "brew_on_path did not put $prefix/bin on PATH" ;;
    esac
}

@test "brew_on_path is idempotent" {
    skip_if_missing brew
    brew_on_path
    local once="$PATH"
    brew_on_path
    brew_on_path
    assert_equal "$PATH" "$once"
}

# ---- brew_install_default_formulas ----------------------------------

@test "brew_install_default_formulas installs requested formulas when brew prefix is writable" {
    mkdir -p "$TEST_TEMP_DIR/homebrew"
    mock_command "brew" '
if [ "$1" = "--prefix" ]; then
    echo "$TEST_TEMP_DIR/homebrew"
    exit 0
fi
if [ "$1" = "list" ] && [ "$2" = "--formula" ] && [ "$3" = "--versions" ]; then
    case "$4" in
        git|tmux|curl|zsh) echo "$4 1.0"; exit 0 ;;
    esac
fi
if [ "$1" = "install" ]; then
    shift
    printf "%s\n" "$*"
    exit 0
fi
exit 1
'

    run brew_install_default_formulas git tmux curl zsh
    assert_success
    assert_output --partial "git tmux curl zsh"
}

@test "brew_install_default_formulas reaches brew install with set -e enabled" {
    mkdir -p "$TEST_TEMP_DIR/homebrew"
    mock_command "brew" '
if [ "$1" = "--prefix" ]; then
    echo "$TEST_TEMP_DIR/homebrew"
    exit 0
fi
if [ "$1" = "list" ] && [ "$2" = "--formula" ] && [ "$3" = "--versions" ]; then
    case "$4" in
        git|tmux|curl|zsh) echo "$4 1.0"; exit 0 ;;
    esac
fi
if [ "$1" = "install" ]; then
    shift
    printf "%s\n" "$*"
    exit 0
fi
exit 1
'

    run bash -c "set -e; source '$DOTPATH/etc/lib/header.sh'; source '$DOTPATH/etc/lib/macos.sh'; brew_install_default_formulas git tmux curl zsh"
    assert_success
    assert_output --partial "git tmux curl zsh"
}

@test "brew_install_default_formulas skips upgrades when prefix is not writable and formulas are installed" {
    mkdir -p "$TEST_TEMP_DIR/homebrew"
    chmod 555 "$TEST_TEMP_DIR/homebrew"
    mock_command "brew" '
if [ "$1" = "--prefix" ]; then
    echo "$TEST_TEMP_DIR/homebrew"
    exit 0
fi
if [ "$1" = "list" ] && [ "$2" = "--formula" ] && [ "$3" = "--versions" ]; then
    case "$4" in
        git|tmux|curl|zsh) echo "$4 1.0"; exit 0 ;;
    esac
fi
if [ "$1" = "install" ]; then
    echo "unexpected install: $*" >&2
    exit 42
fi
exit 1
'

    run brew_install_default_formulas git tmux curl zsh
    assert_success
    assert_output --partial "all default packages are installed"
    assert_output --partial "skip upgrades"
}

@test "brew_install_default_formulas detects unwritable Homebrew subdirectories" {
    mkdir -p "$TEST_TEMP_DIR/homebrew/var/homebrew/locks"
    chmod 555 "$TEST_TEMP_DIR/homebrew/var/homebrew/locks"
    mock_command "brew" '
if [ "$1" = "--prefix" ]; then
    echo "$TEST_TEMP_DIR/homebrew"
    exit 0
fi
if [ "$1" = "list" ] && [ "$2" = "--formula" ] && [ "$3" = "--versions" ]; then
    case "$4" in
        git|tmux|curl|zsh) echo "$4 1.0"; exit 0 ;;
    esac
fi
if [ "$1" = "install" ]; then
    echo "unexpected install: $*" >&2
    exit 42
fi
exit 1
'

    run brew_install_default_formulas git tmux curl zsh
    assert_success
    assert_output --partial "$TEST_TEMP_DIR/homebrew/var/homebrew/locks"
    assert_output --partial "skip upgrades"
}

@test "brew_install_default_formulas fails when prefix is not writable and formulas are missing" {
    mkdir -p "$TEST_TEMP_DIR/homebrew"
    chmod 555 "$TEST_TEMP_DIR/homebrew"
    mock_command "brew" '
if [ "$1" = "--prefix" ]; then
    echo "$TEST_TEMP_DIR/homebrew"
    exit 0
fi
if [ "$1" = "list" ] && [ "$2" = "--formula" ] && [ "$3" = "--versions" ]; then
    case "$4" in
        git|tmux|curl) echo "$4 1.0"; exit 0 ;;
        zsh) exit 1 ;;
    esac
fi
if [ "$1" = "install" ]; then
    echo "unexpected install: $*" >&2
    exit 42
fi
exit 1
'

    run brew_install_default_formulas git tmux curl zsh
    assert_failure
    assert_output --partial "unwritable directories"
    assert_output --partial "zsh"
}

# ---- xcode_clt_installed --------------------------------------------

@test "xcode_clt_installed returns 0 on macOS with CLT" {
    skip_unless_os darwin
    skip_if_missing xcode-select
    # If CLT is installed, the function should agree.
    if xcode-select -p >/dev/null 2>&1 \
       && [ -x "$(xcode-select -p)/usr/bin/git" ]; then
        run xcode_clt_installed
        assert_success
    else
        run xcode_clt_installed
        assert_failure
    fi
}

@test "xcode_clt_installed returns non-zero on Linux" {
    skip_if_os darwin
    # No xcode-select on Linux — function should fail gracefully (non-zero),
    # not crash with set -e.
    run xcode_clt_installed
    assert_failure
}

# ---- ensure_xcode_clt -----------------------------------------------

@test "ensure_xcode_clt is a no-op when CLT already installed" {
    skip_unless_os darwin
    if ! xcode_clt_installed; then
        skip "CLT not installed; can't test the no-op path safely"
    fi
    run ensure_xcode_clt
    assert_success
    assert_output --partial "already installed"
}

# ---- ensure_homebrew ------------------------------------------------

@test "ensure_homebrew is a no-op when brew already installed" {
    skip_if_missing brew
    run ensure_homebrew
    assert_success
    assert_output --partial "already installed"
}

# ---- sourceability --------------------------------------------------

@test "macos.sh is sourceable on any OS without side effects" {
    # Sourcing the file should not execute any install logic by itself.
    run bash -c "source '$DOTPATH/etc/lib/header.sh' && source '$DOTPATH/etc/lib/macos.sh' && echo OK"
    assert_success
    assert_output --partial "OK"
}

@test "macos.sh defines all expected functions" {
    for fn in brew_prefix brew_on_path brew_formula_installed brew_prefix_writable brew_install_default_formulas xcode_clt_installed ensure_xcode_clt ensure_homebrew; do
        run type -t "$fn"
        assert_success
        assert_output "function"
    done
}
