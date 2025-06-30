#!/usr/bin/env bash

# Test script for dotfiles installation in Docker
# This script tests the full installation process

set -euo pipefail

# Color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

assert_exists() {
    local file="$1"
    local desc="${2:-File exists}"
    
    if [ -e "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc: $file"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $desc: $file not found"
        ((TESTS_FAILED++))
    fi
}

assert_symlink() {
    local link="$1"
    local desc="${2:-Symlink exists}"
    
    if [ -L "$link" ]; then
        echo -e "${GREEN}✓${NC} $desc: $link -> $(readlink "$link")"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $desc: $link is not a symlink"
        ((TESTS_FAILED++))
    fi
}

# Test remote installation
test_remote_install() {
    info "Testing remote installation..."
    
    # Download and run setup script
    if bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup)" <<< "y"; then
        info "Remote installation completed"
    else
        error "Remote installation failed"
        return 1
    fi
}

# Run Bats tests
run_bats_tests() {
    info "Running Bats tests..."
    
    cd "$HOME/.dotfiles"
    
    # Install Bats if needed
    if [ ! -x "test/bats" ]; then
        info "Installing Bats..."
        bash test/install_bats.sh
    fi
    
    # Run tests in CI mode
    if test/run_tests.sh --ci; then
        info "Bats tests passed"
        return 0
    else
        error "Bats tests failed"
        return 1
    fi
}

# Test local installation
test_local_install() {
    info "Testing local installation..."
    
    # Clone repository
    if [ ! -d "$HOME/.dotfiles" ]; then
        git clone https://github.com/sskmy1024y/dotfiles.git "$HOME/.dotfiles"
    fi
    
    cd "$HOME/.dotfiles"
    
    # Run make install
    if make install; then
        info "Local installation completed"
    else
        error "Local installation failed"
        return 1
    fi
}

# Verify installation
verify_installation() {
    info "Verifying installation..."
    
    echo -e "\n--- Checking directories ---"
    assert_exists "$HOME/.dotfiles" "Dotfiles directory"
    assert_exists "$HOME/.local/bin" "Local bin directory"
    assert_exists "$HOME/.zsh" "Zsh config directory"
    assert_exists "$HOME/.ssh" "SSH directory"
    assert_exists "$HOME/.git_template/hooks" "Git template directory"
    
    echo -e "\n--- Checking symlinks ---"
    assert_symlink "$HOME/.zshrc" "Zsh config"
    assert_symlink "$HOME/.gitconfig" "Git config"
    assert_symlink "$HOME/.gitignore.global" "Git ignore"
    assert_symlink "$HOME/.tmux.conf" "Tmux config"
    
    echo -e "\n--- Checking zsh configs ---"
    for file in "$HOME"/.dotfiles/config/zsh/*.zsh; do
        basename_file=$(basename "$file")
        assert_symlink "$HOME/.zsh/$basename_file" "Zsh $basename_file"
    done
    
    echo -e "\n--- Checking binary symlinks ---"
    assert_symlink "$HOME/.local/bin/deploy" "Deploy script"
    
    echo -e "\n--- Checking SSH configs ---"
    assert_symlink "$HOME/.ssh/config" "SSH config"
    assert_exists "$HOME/.ssh/authorized_keys" "SSH authorized_keys"
    
    # Check permissions
    echo -e "\n--- Checking permissions ---"
    local ssh_perms=$(stat -c %a "$HOME/.ssh" 2>/dev/null || echo "unknown")
    if [ "$ssh_perms" = "700" ]; then
        echo -e "${GREEN}✓${NC} SSH directory permissions: 700"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} SSH directory permissions: $ssh_perms (expected 700)"
        ((TESTS_FAILED++))
    fi
    
    local auth_perms=$(stat -c %a "$HOME/.ssh/authorized_keys" 2>/dev/null || echo "unknown")
    if [ "$auth_perms" = "600" ]; then
        echo -e "${GREEN}✓${NC} authorized_keys permissions: 600"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} authorized_keys permissions: $auth_perms (expected 600)"
        ((TESTS_FAILED++))
    fi
}

# Test make commands
test_make_commands() {
    info "Testing Makefile commands..."
    
    cd "$HOME/.dotfiles"
    
    # Test make check
    echo -e "\n--- Testing 'make check' ---"
    if make check; then
        echo -e "${GREEN}✓${NC} make check succeeded"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} make check failed"
        ((TESTS_FAILED++))
    fi
    
    # Test make help
    echo -e "\n--- Testing 'make help' ---"
    if make help; then
        echo -e "${GREEN}✓${NC} make help succeeded"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} make help failed"
        ((TESTS_FAILED++))
    fi
}

# Test cleanup
test_cleanup() {
    info "Testing cleanup..."
    
    cd "$HOME/.dotfiles"
    
    # Count symlinks before cleanup
    local before_count=$(find "$HOME" -type l 2>/dev/null | wc -l)
    
    # Run make clean
    if make clean; then
        echo -e "${GREEN}✓${NC} make clean succeeded"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} make clean failed"
        ((TESTS_FAILED++))
    fi
    
    # Check if dotfiles were removed
    if [ ! -d "$HOME/.dotfiles" ]; then
        echo -e "${GREEN}✓${NC} Dotfiles directory removed"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Dotfiles directory still exists"
        ((TESTS_FAILED++))
    fi
    
    # Count symlinks after cleanup
    local after_count=$(find "$HOME" -type l 2>/dev/null | wc -l)
    
    if [ "$after_count" -lt "$before_count" ]; then
        echo -e "${GREEN}✓${NC} Symlinks cleaned up"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Some symlinks may remain"
    fi
}

# Main test flow
main() {
    echo "================================"
    echo "Dotfiles Installation Test"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "User: $USER"
    echo "Home: $HOME"
    echo "================================"
    echo ""
    
    # Choose installation method based on argument
    case "${1:-remote}" in
        remote)
            test_remote_install
            ;;
        local)
            test_local_install
            ;;
        *)
            error "Unknown installation method: $1"
            exit 1
            ;;
    esac
    
    # Run verification tests
    verify_installation
    test_make_commands
    
    # Run Bats tests if installation succeeded
    if [ -d "$HOME/.dotfiles" ]; then
        run_bats_tests
    fi
    
    # Optional: test cleanup
    if [ "${2:-}" = "cleanup" ]; then
        test_cleanup
    fi
    
    # Print summary
    echo ""
    echo "================================"
    echo "Test Summary"
    echo "================================"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main
main "$@"