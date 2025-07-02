#!/usr/bin/env bash

# Script to run macOS Docker test with proper setup

set -euo pipefail

# Color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

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

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
}

# Main script
main() {
    info "Starting macOS Docker test..."
    
    # Check Docker
    check_docker
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
    
    info "Using dotfiles from: $DOTFILES_DIR"
    
    # Run the test using docker compose
    info "Running macOS test container using Docker Compose..."
    cd "$SCRIPT_DIR"
    docker compose -f docker-compose.macos.yml up --build --abort-on-container-exit
    
    info "Test completed!"
}

# Handle script arguments
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h, --help    Show this help message"
        echo ""
        echo "This script runs dotfiles tests in a macOS Docker container."
        echo "The container will be accessible via VNC on port 8006."
        exit 0
        ;;
esac

# Run main
main "$@"