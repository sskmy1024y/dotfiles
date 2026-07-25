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
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $desc: $file not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_symlink() {
    local link="$1"
    local desc="${2:-Symlink exists}"
    
    if [ -L "$link" ]; then
        echo -e "${GREEN}✓${NC} $desc: $link -> $(readlink "$link")"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $desc: $link is not a symlink"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test remote installation
test_remote_install() {
    info "Testing remote installation..."
    local bootstrap_url="${DOTFILES_BOOTSTRAP_URL:-https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap}"
    info "Bootstrap URL: $bootstrap_url"
    
    # Download and run setup script
    # DOTFILES_ASSUME_YES skips the interactive confirmation in etc/install.
    if DOTFILES_ASSUME_YES=1 bash -c "$(curl -fsSL "$bootstrap_url")"; then
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
    
    # Install Bats if needed. The repository tracks the wrapper, but the
    # ignored test/bats dependencies are absent after a fresh clone/archive.
    if [ ! -x "test/bats/bats-core/bin/bats" ]; then
        info "Installing Bats..."
        if [ -f "test/install_bats.sh" ]; then
            bash test/install_bats.sh
        else
            warn "Bats installer not found, skipping Bats tests"
            return 0
        fi
    fi
    
    # Run tests in CI mode
    if [ -f "test/run_tests.sh" ]; then
        if test/run_tests.sh --ci; then
            info "Bats tests passed"
            return 0
        else
            error "Bats tests failed"
            return 1
        fi
    else
        warn "Test runner not found, skipping Bats tests"
        return 0
    fi
}

# Test local installation
test_local_install() {
    info "Testing local installation..."
    
    # Check if we have a mounted local repository
    if [ -d "$HOME/dotfiles-local" ]; then
        info "Using mounted local repository"
        cp -r "$HOME/dotfiles-local" "$HOME/.dotfiles"
    else
        # Clone repository
        if [ ! -d "$HOME/.dotfiles" ]; then
            git clone https://github.com/sskmy1024y/dotfiles.git "$HOME/.dotfiles"
        fi
    fi
    
    cd "$HOME/.dotfiles"
    
    # Drop Terraform state that may have been copied in from the host working
    # tree so the container always starts from a clean slate.
    rm -rf terraform/.terraform terraform/terraform.tfstate terraform/terraform.tfstate.backup

    # On Linux, etc/install automatically disables the brew, macOS-defaults and
    # 1Password modules, so this applies the symlink module only.
    if bash etc/install --yes; then
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
    echo "DEBUG: About to check .local/bin"
    ls -la "$HOME/.local/" 2>&1 || echo "DEBUG: .local does not exist"
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
    assert_exists "$HOME/.ssh/github-key" "GitHub SSH private key"
    assert_exists "$HOME/.ssh/github-key.pub" "GitHub SSH public key"
    assert_exists "$HOME/.tmux/plugins/tpm" "TPM installation"

    if [ -L "$HOME/.claude/agents" ]; then
        echo -e "${RED}✗${NC} Claude agents symlink must not be dangling"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓${NC} No dangling Claude agents symlink"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    
    # Check permissions
    echo -e "\n--- Checking permissions ---"
    local ssh_perms=$(stat -c %a "$HOME/.ssh" 2>/dev/null || echo "unknown")
    if [ "$ssh_perms" = "700" ]; then
        echo -e "${GREEN}✓${NC} SSH directory permissions: 700"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} SSH directory permissions: $ssh_perms (expected 700)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    local auth_perms=$(stat -c %a "$HOME/.ssh/authorized_keys" 2>/dev/null || echo "unknown")
    if [ "$auth_perms" = "600" ]; then
        echo -e "${GREEN}✓${NC} authorized_keys permissions: 600"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} authorized_keys permissions: $auth_perms (expected 600)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test installer entrypoint commands
test_installer_commands() {
    info "Testing installer entrypoint..."
    
    cd "$HOME/.dotfiles"
    
    # Test etc/install --check (preflight; requires terraform on PATH)
    echo -e "\n--- Testing 'etc/install --check' ---"
    if bash etc/install --check; then
        echo -e "${GREEN}✓${NC} etc/install --check succeeded"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} etc/install --check failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test etc/install --help
    echo -e "\n--- Testing 'etc/install --help' ---"
    if bash etc/install --help; then
        echo -e "${GREEN}✓${NC} etc/install --help succeeded"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} etc/install --help failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test cleanup
test_cleanup() {
    info "Testing cleanup..."
    
    cd "$HOME/.dotfiles"
    
    # Count symlinks before cleanup
    local before_count=$(find "$HOME" -type l 2>/dev/null | wc -l)
    
    # Tear down the Terraform-managed symlinks, then remove the checkout.
    if terraform -chdir=terraform destroy -auto-approve \
        -var=enable_brew=false \
        -var=enable_macos_defaults=false \
        -var=enable_1password_ssh=false; then
        echo -e "${GREEN}✓${NC} terraform destroy succeeded"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} terraform destroy failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    cd "$HOME"
    rm -rf "$HOME/.dotfiles"
    
    # Check if dotfiles were removed
    if [ ! -d "$HOME/.dotfiles" ]; then
        echo -e "${GREEN}✓${NC} Dotfiles directory removed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Dotfiles directory still exists"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Count symlinks after cleanup
    local after_count=$(find "$HOME" -type l 2>/dev/null | wc -l)
    
    if [ "$after_count" -lt "$before_count" ]; then
        echo -e "${GREEN}✓${NC} Symlinks cleaned up"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} Some symlinks may remain"
    fi
}

# Main test flow
main() {
    echo "================================"
    echo "Dotfiles Installation Test"
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
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
    
    # etc/install may install Terraform into ~/.local/bin; make sure the
    # follow-up invocations below can find it.
    export PATH="$HOME/.local/bin:$PATH"

    # Run verification tests
    verify_installation
    test_installer_commands
    
    # Run Bats tests if installation succeeded
    if [ -d "$HOME/.dotfiles" ] && [ "${SKIP_BATS_TESTS:-}" != "true" ]; then
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
