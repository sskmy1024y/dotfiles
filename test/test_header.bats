#!/usr/bin/env bats

# Focused tests for shared shell helpers.

load test_helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "OS detection returns a supported value" {
    run detect_os

    assert_success
    case "$output" in
        darwin | ubuntu | debian | archlinux | android | windows | unknown) ;;
        *) fail "unexpected OS: $output" ;;
    esac
}

@test "command detection handles commands, builtins, and missing names" {
    run is_exists bash
    assert_success
    run has cd
    assert_success
    run is_exists nonexistent_command_12345
    assert_failure
    run has nonexistent_command_12345
    assert_failure
}

@test "logging helpers retain their prefixes" {
    run bash -c "source '$DOTPATH/etc/lib/header.sh'; info info; warn warn; error error; log log"

    assert_success
    assert_output --partial "[+] info"
    assert_output --partial "[*] warn"
    assert_output --partial "[-] error"
    assert_output --partial "log"
}

@test "symlink creates a link and is idempotent" {
    local source_file="$TEST_TEMP_DIR/source.txt"
    local target_file="$TEST_TEMP_DIR/target.txt"
    create_test_file "$source_file" "content"

    symlink "$source_file" "$target_file"
    local first_inode
    first_inode="$(ls -i "$target_file" | awk '{print $1}')"
    symlink "$source_file" "$target_file"

    assert_link_exists "$target_file"
    assert_symlink_to "$source_file" "$target_file"
    assert_equal "$(ls -i "$target_file" | awk '{print $1}')" "$first_inode"
}

@test "symlink preserves an existing regular file" {
    local source_file="$TEST_TEMP_DIR/source.txt"
    local target_file="$TEST_TEMP_DIR/target.txt"
    create_test_file "$source_file" "source"
    create_test_file "$target_file" "existing"

    run symlink "$source_file" "$target_file"

    assert_success
    assert_not_link_exists "$target_file"
    assert_file_contains "$target_file" "existing"
}

@test "wild_symlink links only matching files" {
    mkdir -p "$TEST_TEMP_DIR/source" "$TEST_TEMP_DIR/target"
    create_test_file "$TEST_TEMP_DIR/source/one.txt"
    create_test_file "$TEST_TEMP_DIR/source/two.txt"
    create_test_file "$TEST_TEMP_DIR/source/skip.conf"

    run wild_symlink "$TEST_TEMP_DIR/source/*.txt" "$TEST_TEMP_DIR/target/"

    assert_success
    assert_link_exists "$TEST_TEMP_DIR/target/one.txt"
    assert_link_exists "$TEST_TEMP_DIR/target/two.txt"
    assert_not_exists "$TEST_TEMP_DIR/target/skip.conf"
}
