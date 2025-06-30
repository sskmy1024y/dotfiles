#!/usr/bin/env bash

# Install Bats testing framework
# This script installs Bats and its dependencies

set -euo pipefail

# Color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

# Get test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_DIR="$TEST_DIR/bats"

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Install Bats
install_bats() {
    info "Installing Bats testing framework..."
    
    # Create bats directory
    mkdir -p "$BATS_DIR"
    
    # Clone Bats core
    if [ ! -d "$BATS_DIR/bats-core" ]; then
        info "Cloning bats-core..."
        git clone https://github.com/bats-core/bats-core.git "$BATS_DIR/bats-core"
    else
        info "Updating bats-core..."
        cd "$BATS_DIR/bats-core" && git pull
    fi
    
    # Clone Bats support (for better assertions)
    if [ ! -d "$BATS_DIR/bats-support" ]; then
        info "Cloning bats-support..."
        git clone https://github.com/bats-core/bats-support.git "$BATS_DIR/bats-support"
    else
        info "Updating bats-support..."
        cd "$BATS_DIR/bats-support" && git pull
    fi
    
    # Clone Bats assert (for better assertions)
    if [ ! -d "$BATS_DIR/bats-assert" ]; then
        info "Cloning bats-assert..."
        git clone https://github.com/bats-core/bats-assert.git "$BATS_DIR/bats-assert"
    else
        info "Updating bats-assert..."
        cd "$BATS_DIR/bats-assert" && git pull
    fi
    
    # Clone Bats file (for file testing)
    if [ ! -d "$BATS_DIR/bats-file" ]; then
        info "Cloning bats-file..."
        git clone https://github.com/bats-core/bats-file.git "$BATS_DIR/bats-file"
    else
        info "Updating bats-file..."
        cd "$BATS_DIR/bats-file" && git pull
    fi
    
    info "Bats installation completed!"
}

# Create bats wrapper script
create_wrapper() {
    info "Creating bats wrapper script..."
    
    # Remove old wrapper if it exists
    if [ -e "$TEST_DIR/bats" ] && [ ! -d "$TEST_DIR/bats" ]; then
        rm -f "$TEST_DIR/bats"
    fi
    
    # Create wrapper script with different name
    cat > "$TEST_DIR/bats-runner" << 'EOF'
#!/usr/bin/env bash
# Wrapper script for running bats with local installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/bats/bats-core/bin/bats" "$@"
EOF
    
    chmod +x "$TEST_DIR/bats-runner"
    
    # Create symlink for compatibility
    if [ ! -e "$TEST_DIR/bats" ] || [ -L "$TEST_DIR/bats" ]; then
        ln -sf bats-runner "$TEST_DIR/bats"
    fi
    
    info "Wrapper script created at: $TEST_DIR/bats-runner"
}

# Main
main() {
    info "Setting up Bats testing framework..."
    install_bats
    create_wrapper
    
    echo ""
    info "Setup completed!"
    info "You can now run tests with: ./test/bats <test-file>.bats"
    info "Or run all tests with: make test"
}

main