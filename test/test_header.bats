#!/usr/bin/env bats

# Test for header.sh functions

load test_helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

# Test detect_os function
@test "detect_os returns valid OS" {
    run detect_os
    assert_success
    assert [ -n "$output" ]
    
    case "$output" in
        darwin|ubuntu|debian|archlinux|android|windows|unknown)
            assert_success
            ;;
        *)
            fail "detect_os returned unexpected value: $output"
            ;;
    esac
}

# Test is_exists function
@test "is_exists finds existing commands" {
    run is_exists bash
    assert_success
    
    run is_exists sh
    assert_success
}

@test "is_exists fails for non-existent commands" {
    run is_exists nonexistent_command_12345
    assert_failure
}

# Test has function
@test "has finds builtin commands" {
    run has cd
    assert_success
    
    run has echo
    assert_success
}

@test "has fails for non-existent commands" {
    run has nonexistent_command_12345
    assert_failure
}

# Test is_bash function
@test "is_bash detects bash shell" {
    if [ -n "$BASH_VERSION" ]; then
        run is_bash
        assert_success
    else
        run is_bash
        assert_failure
    fi
}

# Test color output functions
@test "info function outputs without error" {
    run info "Test info message"
    assert_success
    assert_output --partial "[+]"
    assert_output --partial "Test info message"
}

@test "error function outputs without error" {
    run error "Test error message"
    assert_success
    assert_output --partial "[-]"
    assert_output --partial "Test error message"
}

@test "warn function outputs without error" {
    run warn "Test warning message"
    assert_success
    assert_output --partial "[*]"
    assert_output --partial "Test warning message"
}

@test "log function outputs without error" {
    run log "Test log message"
    assert_success
    assert_output --partial "Test log message"
}

# Test symlink function
@test "symlink creates symbolic link" {
    local source_file="$TEST_TEMP_DIR/source.txt"
    local target_file="$TEST_TEMP_DIR/target.txt"
    
    # Create source file
    create_test_file "$source_file" "test content"
    
    # Create symlink
    run symlink "$source_file" "$target_file"
    assert_success
    
    # Verify symlink exists
    assert_link_exists "$target_file"
    # assert_symlink_to expects: sourcefile(target) link
    assert_symlink_to "$source_file" "$target_file"
    
    # Verify content
    run cat "$target_file"
    assert_success
    assert_output "test content"
}

@test "symlink doesn't overwrite existing link" {
    local source_file="$TEST_TEMP_DIR/source.txt"
    local target_file="$TEST_TEMP_DIR/target.txt"
    
    # Create source file
    create_test_file "$source_file" "test content"
    
    # Create symlink twice
    symlink "$source_file" "$target_file"
    local first_inode=$(ls -i "$target_file" | awk '{print $1}')
    
    # Modify source and try to create symlink again
    echo "new content" > "$source_file"
    symlink "$source_file" "$target_file"
    local second_inode=$(ls -i "$target_file" | awk '{print $1}')
    
    # Verify the symlink wasn't recreated
    assert_equal "$first_inode" "$second_inode"
    
    # Content should reflect the new content (symlink points to modified file)
    run cat "$target_file"
    assert_output "new content"
}

@test "symlink doesn't overwrite existing file" {
    local source_file="$TEST_TEMP_DIR/source.txt"
    local target_file="$TEST_TEMP_DIR/target.txt"
    
    # Create source and target files
    create_test_file "$source_file" "source content"
    create_test_file "$target_file" "existing content"
    
    # Try to create symlink
    run symlink "$source_file" "$target_file"
    assert_success
    
    # Target should still be a regular file
    assert_file_exists "$target_file"
    assert_not_link_exists "$target_file"
    
    # Content should be unchanged
    run cat "$target_file"
    assert_output "existing content"
}

# Test wild_symlink function
@test "wild_symlink creates multiple symlinks" {
    local source_dir="$TEST_TEMP_DIR/source"
    local target_dir="$TEST_TEMP_DIR/target"
    
    mkdir -p "$source_dir" "$target_dir"
    
    # Create test files
    create_test_file "$source_dir/file1.txt" "file1"
    create_test_file "$source_dir/file2.txt" "file2"
    create_test_file "$source_dir/file3.conf" "file3"
    
    # Create wildcard symlinks
    run wild_symlink "$source_dir/*.txt" "$target_dir/"
    assert_success
    
    # Check symlinks were created
    assert_link_exists "$target_dir/file1.txt"
    assert_link_exists "$target_dir/file2.txt"
    assert_not_exists "$target_dir/file3.conf"
    
    # Verify content
    run cat "$target_dir/file1.txt"
    assert_output "file1"
    
    run cat "$target_dir/file2.txt"
    assert_output "file2"
}

# Test linux_distribution function
@test "linux_distribution returns valid distribution on Linux" {
    local os=$(detect_os)
    if [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "archlinux" || "$os" == "android" ]]; then
        run linux_distribution
        assert_success
        
        case "$output" in
            ubuntu|debian|archlinux|android|unkown_linux)
                assert_success
                ;;
            *)
                fail "linux_distribution returned unexpected value: $output"
                ;;
        esac
    else
        skip "Not running on Linux"
    fi
}

# Test OS detection on different platforms
@test "detect_os returns darwin on macOS" {
    skip_unless_os "darwin"
    run detect_os
    assert_output "darwin"
}

@test "detect_os returns ubuntu on Ubuntu" {
    skip_unless_os "ubuntu"
    run detect_os
    assert_output "ubuntu"
}

@test "detect_os returns archlinux on Arch Linux" {
    skip_unless_os "archlinux"
    run detect_os
    assert_output "archlinux"
}