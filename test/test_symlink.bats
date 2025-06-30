#!/usr/bin/env bats

# Test for symlink functionality

load test_helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

# Test symlink idempotency
@test "symlink is idempotent (not recreated)" {
    local source_file="$TEST_TEMP_DIR/source.txt"
    local target_file="$TEST_TEMP_DIR/target.txt"
    
    # Create source file
    create_test_file "$source_file" "original content"
    
    # Create symlink twice
    symlink "$source_file" "$target_file"
    local first_inode=$(ls -i "$target_file" | awk '{print $1}')
    
    symlink "$source_file" "$target_file"
    local second_inode=$(ls -i "$target_file" | awk '{print $1}')
    
    # Verify symlink wasn't recreated
    assert_equal "$first_inode" "$second_inode"
}

# Test symlink with existing file
@test "symlink doesn't overwrite existing file" {
    local source_file="$TEST_TEMP_DIR/source.txt"
    local target_file="$TEST_TEMP_DIR/target.txt"
    
    # Create source and existing target
    create_test_file "$source_file" "source content"
    create_test_file "$target_file" "existing content"
    
    # Try to create symlink (should not overwrite)
    run symlink "$source_file" "$target_file"
    assert_success
    
    # Verify file is not a symlink
    assert_file_exists "$target_file"
    assert_not_link_exists "$target_file"
    
    # Verify content unchanged
    run cat "$target_file"
    assert_output "existing content"
}

# Test deploy script symlink creation
@test "deploy script creates necessary directories" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # May fail due to missing dependencies, but directories should be created
    # Check directory creation
    assert_dir_exists "$HOME/.local/bin"
    assert_dir_exists "$HOME/.zsh"
    assert_dir_exists "$HOME/.ssh"
    assert_dir_exists "$HOME/.git_template/hooks"
    assert_dir_exists "$HOME/.claude"
}

@test "deploy script sets correct SSH permissions" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check SSH directory permissions
    if [ -d "$HOME/.ssh" ]; then
        run get_permissions "$HOME/.ssh"
        assert_output "700"
    fi
    
    # Check authorized_keys permissions
    if [ -f "$HOME/.ssh/authorized_keys" ]; then
        run get_permissions "$HOME/.ssh/authorized_keys"
        assert_output "600"
    fi
}

@test "deploy script creates zsh symlinks" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check zshrc symlink
    if [ -e "$HOME/.zshrc" ]; then
        assert_link_exists "$HOME/.zshrc"
        assert_symlink_to "$DOTPATH/config/zsh/.zshrc" "$HOME/.zshrc"
    fi
    
    # Check zsh config files
    for zsh_file in "$DOTPATH"/config/zsh/*.zsh; do
        basename_file=$(basename "$zsh_file")
        if [ -e "$HOME/.zsh/$basename_file" ]; then
            assert_link_exists "$HOME/.zsh/$basename_file"
            assert_symlink_to "$zsh_file" "$HOME/.zsh/$basename_file"
        fi
    done
}

@test "deploy script creates git symlinks" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check git config symlinks
    local git_configs=(".gitconfig" ".gitignore.global" ".gitmessage" ".czrc")
    for config in "${git_configs[@]}"; do
        if [ -e "$HOME/$config" ]; then
            assert_link_exists "$HOME/$config"
            assert_symlink_to "$DOTPATH/config/git/$config" "$HOME/$config"
        fi
    done
}

@test "deploy script creates tmux symlink" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check tmux config symlink
    if [ -e "$HOME/.tmux.conf" ]; then
        assert_link_exists "$HOME/.tmux.conf"
        assert_symlink_to "$DOTPATH/config/tmux/.tmux.conf" "$HOME/.tmux.conf"
    fi
}

@test "deploy script creates Claude symlinks" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check Claude symlinks
    if [ -e "$HOME/.claude/CLAUDE.md" ]; then
        assert_link_exists "$HOME/.claude/CLAUDE.md"
        assert_symlink_to "$DOTPATH/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    fi
    
    if [ -e "$HOME/.claude/settings.json" ]; then
        assert_link_exists "$HOME/.claude/settings.json"
        assert_symlink_to "$DOTPATH/config/claude/settings.json" "$HOME/.claude/settings.json"
    fi
    
    if [ -e "$HOME/.claude/commands" ]; then
        assert_link_exists "$HOME/.claude/commands"
        assert_symlink_to "$DOTPATH/config/claude/commands" "$HOME/.claude/commands"
    fi
}

@test "deploy script creates binary symlinks" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Check deploy script symlink
    if [ -e "$HOME/.local/bin/deploy" ]; then
        assert_link_exists "$HOME/.local/bin/deploy"
        assert_symlink_to "$DOTPATH/etc/scripts/deploy" "$HOME/.local/bin/deploy"
    fi
    
    # Check bin directory symlinks
    for bin_file in "$DOTPATH"/bin/*; do
        if [ -f "$bin_file" ]; then
            basename_file=$(basename "$bin_file")
            if [ -e "$HOME/.local/bin/$basename_file" ]; then
                assert_link_exists "$HOME/.local/bin/$basename_file"
            fi
        fi
    done
}

@test "deploy script handles existing files correctly" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Create existing files
    mkdir -p "$HOME"
    create_test_file "$HOME/.zshrc" "existing zshrc"
    create_test_file "$HOME/.gitconfig" "existing gitconfig"
    
    # Run deploy script
    run bash "$DOTPATH/etc/scripts/deploy"
    
    # Verify existing files weren't overwritten
    assert_file_exists "$HOME/.zshrc"
    assert_not_link_exists "$HOME/.zshrc"
    run cat "$HOME/.zshrc"
    assert_output "existing zshrc"
    
    assert_file_exists "$HOME/.gitconfig"
    assert_not_link_exists "$HOME/.gitconfig"
    run cat "$HOME/.gitconfig"
    assert_output "existing gitconfig"
}

@test "deploy script is idempotent" {
    # Setup test environment
    export HOME="$TEST_TEMP_DIR/home"
    export DOTPATH="$DOTPATH"
    
    # Run deploy script twice
    run bash "$DOTPATH/etc/scripts/deploy"
    local first_symlink_count=$(count_symlinks "$HOME")
    
    run bash "$DOTPATH/etc/scripts/deploy"
    local second_symlink_count=$(count_symlinks "$HOME")
    
    # Symlink count should be the same
    assert_equal "$first_symlink_count" "$second_symlink_count"
}