#!/usr/bin/env bats

# Test for syntax checking and code quality

load test_helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

# Files to exclude from checks
EXCLUDE_PATTERNS=(
    "*.zsh"
    "*.zsh_"
    "*/\.git/*"
    "*/\.vscode/*"
    "*/doc/*"
    "*/README*"
    "*/test/bats/*"
)

# Check if file should be excluded
should_exclude() {
    local file="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$file" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Find all shell scripts
find_shell_scripts() {
    local scripts=()
    
    # Find .sh files
    while IFS= read -r -d '' file; do
        if ! should_exclude "$file"; then
            scripts+=("$file")
        fi
    done < <(find "$DOTPATH" -name "*.sh" -type f -print0)
    
    # Find files with bash/sh shebang
    while IFS= read -r -d '' file; do
        if ! should_exclude "$file" && ! [[ "$file" == *.sh ]]; then
            if head -n1 "$file" 2>/dev/null | grep -qE '^#!/(usr/)?bin/(env )?(bash|sh)'; then
                scripts+=("$file")
            fi
        fi
    done < <(find "$DOTPATH" -type f -print0)
    
    # Remove duplicates
    printf '%s\n' "${scripts[@]}" | sort -u
}

# Test all shell scripts have valid syntax
@test "all shell scripts have valid bash syntax" {
    local scripts
    local failed=0
    
    # Read scripts into array
    mapfile -t scripts < <(find_shell_scripts)
    
    # Check each script
    for script in "${scripts[@]}"; do
        if ! bash -n "$script" 2>/dev/null; then
            echo "Syntax error in: ${script#$DOTPATH/}"
            ((failed++))
        fi
    done
    
    [ $failed -eq 0 ]
}

# Test deploy script syntax
@test "deploy script has valid syntax" {
    run bash -n "$DOTPATH/etc/scripts/deploy"
    assert_success
}

# Test init script syntax
@test "init script has valid syntax" {
    run bash -n "$DOTPATH/etc/scripts/init"
    assert_success
}

# Test setup script syntax
@test "setup script has valid syntax" {
    run bash -n "$DOTPATH/etc/setup"
    assert_success
}

# Test header.sh syntax
@test "header.sh has valid syntax" {
    run bash -n "$DOTPATH/etc/lib/header.sh"
    assert_success
}

# Test install scripts syntax
@test "all install.d scripts have valid syntax" {
    for script in "$DOTPATH"/etc/scripts/install.d/*.sh; do
        if [ -f "$script" ]; then
            run bash -n "$script"
            assert_success
        fi
    done
}

# Test for ShellCheck if available
@test "scripts pass ShellCheck (if available)" {
    skip_if_missing "shellcheck"
    
    local scripts
    local failed=0
    
    # ShellCheck exclusions
    local excludes=(
        "SC1090"  # Can't follow non-constant source
        "SC1091"  # Not following sourced files
        "SC2034"  # Unused variables (often used in sourced files)
    )
    
    local exclude_args=""
    for code in "${excludes[@]}"; do
        exclude_args="$exclude_args -e $code"
    done
    
    # Read scripts into array
    mapfile -t scripts < <(find_shell_scripts)
    
    # Check each script
    for script in "${scripts[@]}"; do
        if ! shellcheck $exclude_args "$script" 2>/dev/null; then
            echo "ShellCheck warnings in: ${script#$DOTPATH/}"
            ((failed++))
        fi
    done
    
    [ $failed -eq 0 ]
}

# Test for error handling
@test "critical scripts have error handling (set -e)" {
    local scripts=(
        "$DOTPATH/etc/scripts/deploy"
        "$DOTPATH/etc/scripts/init"
        "$DOTPATH/etc/setup"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            run grep -E "set -e|set -o errexit" "$script"
            assert_success
        fi
    done
}

# Test for hardcoded paths
@test "no hardcoded home paths in shell scripts" {
    local scripts
    local found=0
    
    # Read scripts into array
    mapfile -t scripts < <(find_shell_scripts)
    
    # Check each script
    for script in "${scripts[@]}"; do
        if grep -q "/Users/\|/home/" "$script" 2>/dev/null; then
            # Allow specific exceptions (like in test files or comments)
            if ! grep -v "^#" "$script" | grep -q "/Users/\|/home/"; then
                continue
            fi
            echo "Hardcoded path in: ${script#$DOTPATH/}"
            ((found++))
        fi
    done
    
    [ $found -eq 0 ]
}

# Test Makefile
@test "Makefile has valid syntax" {
    run make -n check
    assert_success
}

@test "Makefile help target exists" {
    run make -n help
    assert_success
}

@test "Makefile test target exists" {
    run make -n test
    assert_success
}

# Test for consistent file permissions
@test "executable scripts have correct permissions" {
    local scripts=(
        "$DOTPATH/etc/scripts/deploy"
        "$DOTPATH/etc/scripts/init"
        "$DOTPATH/etc/setup"
        "$DOTPATH/test/install_bats.sh"
        "$DOTPATH/test/bats"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            assert [ -x "$script" ]
        fi
    done
}

# Test bats files
@test "all bats test files have valid syntax" {
    # Ensure bats is available
    if [ -x "$TEST_DIR/bats" ]; then
        for bats_file in "$TEST_DIR"/*.bats; do
            if [ -f "$bats_file" ]; then
                run "$TEST_DIR/bats" --dry-run "$bats_file"
                assert_success
            fi
        done
    else
        skip "Bats not installed"
    fi
}

# Test for common shell script issues
@test "scripts don't use deprecated syntax" {
    local scripts
    local found=0
    
    # Read scripts into array
    mapfile -t scripts < <(find_shell_scripts)
    
    # Check for backticks (should use $() instead)
    for script in "${scripts[@]}"; do
        if grep -E '`[^`]+`' "$script" 2>/dev/null; then
            echo "Deprecated backticks in: ${script#$DOTPATH/}"
            ((found++))
        fi
    done
    
    [ $found -eq 0 ]
}

# Test script documentation
@test "main scripts have proper headers" {
    local scripts=(
        "$DOTPATH/etc/scripts/deploy"
        "$DOTPATH/etc/scripts/init"
        "$DOTPATH/etc/setup"
        "$DOTPATH/etc/lib/header.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            # Check for shebang
            run head -n1 "$script"
            assert_output --regexp '^#!/'
            
            # Check for author or description comment
            run head -n10 "$script"
            assert_output --partial "Author:"
        fi
    done
}