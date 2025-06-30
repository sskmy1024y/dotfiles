#!/usr/bin/env bash

# Common test helper functions for Bats tests

# Get directories
export TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTPATH="$(cd "$TEST_DIR/.." && pwd)"
export BATS_LIBS_DIR="$TEST_DIR/bats"

# Load bats libraries
if [ -d "$BATS_LIBS_DIR" ]; then
    load "$BATS_LIBS_DIR/bats-support/load"
    load "$BATS_LIBS_DIR/bats-assert/load"
    load "$BATS_LIBS_DIR/bats-file/load"
fi

# Source the header.sh file for testing
source "$DOTPATH/etc/lib/header.sh"

# Create temporary test directory
setup_test_dir() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export ORIGINAL_HOME="$HOME"
    export ORIGINAL_DOTPATH="${DOTPATH:-}"
}

# Clean up temporary test directory
teardown_test_dir() {
    if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    if [ -n "${ORIGINAL_HOME:-}" ]; then
        export HOME="$ORIGINAL_HOME"
    fi
    if [ -n "${ORIGINAL_DOTPATH:-}" ]; then
        export DOTPATH="$ORIGINAL_DOTPATH"
    fi
}

# Create a test file with content
create_test_file() {
    local file="$1"
    local content="${2:-test content}"
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Mock a command
mock_command() {
    local cmd="$1"
    local mock_script="$2"
    
    # Create mock directory in PATH
    local mock_dir="$TEST_TEMP_DIR/mocks"
    mkdir -p "$mock_dir"
    
    # Create mock script
    cat > "$mock_dir/$cmd" << EOF
#!/usr/bin/env bash
$mock_script
EOF
    chmod +x "$mock_dir/$cmd"
    
    # Add to PATH
    export PATH="$mock_dir:$PATH"
}

# Count files in directory
count_files() {
    local dir="$1"
    local pattern="${2:-*}"
    find "$dir" -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' '
}

# Count symlinks in directory
count_symlinks() {
    local dir="$1"
    find "$dir" -type l 2>/dev/null | wc -l | tr -d ' '
}

# Get file permissions (portable)
get_permissions() {
    local file="$1"
    if [ "$(uname)" = "Darwin" ]; then
        stat -f %p "$file" 2>/dev/null | tail -c 4
    else
        stat -c %a "$file" 2>/dev/null
    fi
}

# Assert file has specific permissions
assert_permissions() {
    local file="$1"
    local expected="$2"
    local actual=$(get_permissions "$file")
    [ "$actual" = "$expected" ]
}

# Skip test if on specific OS
skip_if_os() {
    local os="$1"
    local current_os=$(detect_os)
    if [ "$current_os" = "$os" ]; then
        skip "Skipping on $os"
    fi
}

# Skip test if not on specific OS
skip_unless_os() {
    local os="$1"
    local current_os=$(detect_os)
    if [ "$current_os" != "$os" ]; then
        skip "Only runs on $os"
    fi
}

# Skip test if command not available
skip_if_missing() {
    local cmd="$1"
    if ! command_exists "$cmd"; then
        skip "$cmd not available"
    fi
}

# Assert file is not a symlink
assert_not_link_exists() {
    local file="$1"
    if [ -L "$file" ]; then
        fail "$file is a symlink (expected not to be)"
        return 1
    fi
    return 0
}

# Assert file is not exists
assert_not_exists() {
    local file="$1"
    if [ -e "$file" ]; then
        fail "$file exists (expected not to exist)"
        return 1
    fi
    return 0
}