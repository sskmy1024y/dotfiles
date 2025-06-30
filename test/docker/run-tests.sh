#!/usr/bin/env bash

# Convenience script for running Docker tests with different configurations
# Usage: ./run-tests.sh [OS] [INSTALL_METHOD] [--cleanup]

set -euo pipefail

# Default values
OS="${1:-ubuntu}"
INSTALL_METHOD="${2:-remote}"
RUN_CLEANUP="false"

# Check for cleanup flag
if [[ "${3:-}" == "--cleanup" ]]; then
    RUN_CLEANUP="true"
fi

# Color codes
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${BLUE}=== Dotfiles Docker Test Runner ===${NC}"
echo -e "${GREEN}OS:${NC} $OS"
echo -e "${GREEN}Install Method:${NC} $INSTALL_METHOD"
echo -e "${GREEN}Cleanup:${NC} $RUN_CLEANUP"
echo ""

# Export environment variables
export OS
export INSTALL_METHOD
export RUN_CLEANUP

# Build and run test
echo -e "${YELLOW}Building Docker image...${NC}"
docker compose build test

echo -e "${YELLOW}Running tests...${NC}"
docker compose run --rm test

echo -e "${GREEN}Test completed!${NC}"
