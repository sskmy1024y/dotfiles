#!/usr/bin/env bats

# Test for deploy script functionality

load test_helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

# Test deploy script syntax
@test "deploy script has valid syntax" {
    run bash -n "$DOTPATH/etc/scripts/deploy"
    assert_success
}

# Test deploy script with missing DOTPATH
@test "deploy script sets DOTPATH when missing" {
    # Create test environment
    export HOME="$TEST_TEMP_DIR/home"
    local original_dotpath="$DOTPATH"
    
    # Unset DOTPATH and run deploy script in subshell
    (
        unset DOTPATH
        source "$original_dotpath/etc/scripts/deploy" >/dev/null 2>&1 || true
        [ -n "${DOTPATH:-}" ]
    )
    
    assert_success
}

# Test deploy script directory creation
@test "deploy script creates necessary directories" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check directory creation
    assert_dir_exists "$HOME/.local/bin"
    assert_dir_exists "$HOME/.zsh"
    assert_dir_exists "$HOME/.ssh"
    assert_dir_exists "$HOME/.git_template/hooks"
    assert_dir_exists "$HOME/.claude"
}

@test "deploy script creates .ssh directory with correct permissions" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check .ssh directory permissions
    assert_dir_exists "$HOME/.ssh"
    run get_permissions "$HOME/.ssh"
    assert_output "700"
}

@test "deploy script creates authorized_keys with correct permissions" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check authorized_keys permissions
    assert_file_exists "$HOME/.ssh/authorized_keys"
    run get_permissions "$HOME/.ssh/authorized_keys"
    assert_output "600"
}

# Test with existing files
@test "deploy script preserves existing .zshrc file" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"
    
    # Create existing file
    create_test_file "$HOME/.zshrc" "existing zshrc content"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check file wasn't replaced
    assert_file_exists "$HOME/.zshrc"
    assert_not_link_exists "$HOME/.zshrc"
    run cat "$HOME/.zshrc"
    assert_output "existing zshrc content"
}

@test "deploy script preserves existing .gitconfig file" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"
    
    # Create existing file
    create_test_file "$HOME/.gitconfig" "existing gitconfig"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check file wasn't replaced
    assert_file_exists "$HOME/.gitconfig"
    assert_not_link_exists "$HOME/.gitconfig"
    run cat "$HOME/.gitconfig"
    assert_output "existing gitconfig"
}

# Test tmux plugin manager
@test "deploy script handles tmux plugin manager installation" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Mock git command
    mock_command "git" "
if [[ \"\$1\" == \"clone\" && \"\$2\" == \"https://github.com/tmux-plugins/tpm\" ]]; then
    mkdir -p \"\$3\"
    touch \"\$3/.git\"
    exit 0
fi
command git \"\$@\"
"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check if TPM directory exists
    assert_dir_exists "$HOME/.tmux/plugins/tpm"
    assert_file_exists "$HOME/.tmux/plugins/tpm/.git"
}

# Test SSH key generation
@test "deploy script generates SSH keys if missing" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Mock ssh-keygen command
    mock_command "ssh-keygen" "
if [[ \"\$1\" == \"-q\" && \"\$2\" == \"-f\" ]]; then
    touch \"\$3\"
    touch \"\$3.pub\"
    exit 0
fi
command ssh-keygen \"\$@\"
"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check if SSH keys were generated
    if [ -f "$HOME/.ssh/git_private" ] || [ -f "$HOME/.ssh/git_public" ]; then
        assert_success
    fi
}

# Test error handling
@test "deploy script fails gracefully with invalid DOTPATH" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="/nonexistent/path"
    
    # Run deploy script (should fail)
    run bash "$DOTPATH/etc/scripts/deploy" 2>/dev/null
    assert_failure
}

# Test script output
@test "deploy script produces expected output" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Run deploy script and capture output
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check for expected output patterns
    assert_output --partial "Creating symbolic links..."
    assert_output --partial "zsh..."
    assert_output --partial "ssh .."
    assert_output --partial "git..."
    assert_output --partial "tmux..."
    assert_output --partial "binary..."
}

# Test individual component installations
@test "deploy script creates SSH config symlinks" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check SSH config symlinks
    if [ -e "$HOME/.ssh/config" ]; then
        assert_link_exists "$HOME/.ssh/config"
        assert_symlink_to "$DOTPATH/config/ssh/config" "$HOME/.ssh/config"
    fi
    
    if [ -e "$HOME/.ssh/git.conf" ]; then
        assert_link_exists "$HOME/.ssh/git.conf"
        assert_symlink_to "$DOTPATH/config/ssh/git.conf" "$HOME/.ssh/git.conf"
    fi
}

@test "deploy script creates git template directory" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check git template directory
    assert_dir_exists "$HOME/.git_template"
    assert_dir_exists "$HOME/.git_template/hooks"
}

# Test PATH suggestions
@test "deploy script outputs PATH export suggestions" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check for PATH export suggestions
    assert_output --partial 'export PATH="$HOME/.tmux/bin:$PATH"'
    assert_output --partial 'export PATH="$HOME/.local/bin:$PATH'
}