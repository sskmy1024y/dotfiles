#!/usr/bin/env bash

# Main test runner for dotfiles using Bats
# Author: Claude
# Description: Runs all Bats test suites and generates a summary report

set -euo pipefail

# Get the directory of this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTPATH="$(cd "$TEST_DIR/.." && pwd)"

# Color codes for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
NC="\033[0m" # No Color

# Timing
START_TIME=$(date +%s)

# Bats executable
BATS_BIN="$TEST_DIR/bats-runner"
# Fallback to symlink
if [ ! -x "$BATS_BIN" ] && [ -x "$TEST_DIR/bats" ]; then
    BATS_BIN="$TEST_DIR/bats"
fi

# Print header
print_header() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║     Dotfiles Test Suite Runner         ║${NC}"
    echo -e "${BOLD}${BLUE}║           (Using Bats)                 ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "DOTPATH: $DOTPATH"
    echo "Date: $(date)"
    echo ""
}

# Install Bats if needed
install_bats_if_needed() {
    if [ ! -x "$BATS_BIN" ]; then
        echo -e "${YELLOW}Bats not found. Installing...${NC}"
        if [ -x "$TEST_DIR/install_bats.sh" ]; then
            bash "$TEST_DIR/install_bats.sh"
        else
            echo -e "${RED}Error: install_bats.sh not found${NC}"
            exit 1
        fi
    fi
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BOLD}${YELLOW}Checking prerequisites...${NC}"
    
    # Check for bash 4+ (recommended for mapfile)
    if [ "${BASH_VERSION%%.*}" -lt 4 ]; then
        echo -e "${YELLOW}⚠ Warning: Bash version 4+ recommended (found: $BASH_VERSION)${NC}"
        echo "  Some tests may not work correctly with older Bash versions"
    else
        echo -e "${GREEN}✓ Bash version: $BASH_VERSION${NC}"
    fi
    
    # Check for Bats
    if [ -x "$BATS_BIN" ]; then
        echo -e "${GREEN}✓ Bats is installed${NC}"
    else
        echo -e "${YELLOW}⚠ Bats not found - will be installed${NC}"
    fi
    
    # Check for optional tools
    if command -v shellcheck >/dev/null 2>&1; then
        echo -e "${GREEN}✓ ShellCheck is installed${NC}"
    else
        echo -e "${YELLOW}⚠ ShellCheck not found - some tests will be skipped${NC}"
        echo "  Install with: brew install shellcheck (macOS) or apt-get install shellcheck (Ubuntu)"
    fi
    
    echo ""
    return 0
}

# Run a single Bats test file
run_bats_test() {
    local test_name="$1"
    local test_file="$2"
    
    echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Running: $test_name${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -f "$test_file" ]; then
        echo -e "${RED}✗ Test file not found: $test_file${NC}"
        return 1
    fi
    
    # Run Bats test with TAP output for better parsing
    if "$BATS_BIN" "$test_file"; then
        return 0
    else
        return 1
    fi
}

# Run all tests
run_all_tests() {
    local test_files=(
        "test_header.bats:Unit Tests - Header Functions"
        "test_symlink.bats:Integration Tests - Symlinks"
        "test_deploy.bats:Integration Tests - Deploy Script"
        "test_syntax.bats:Code Quality - Syntax & Linting"
    )
    
    local suite_results=()
    local total_passed=0
    local total_failed=0
    
    for test_spec in "${test_files[@]}"; do
        IFS=':' read -r file name <<< "$test_spec"
        local test_file="$TEST_DIR/$file"
        
        if run_bats_test "$name" "$test_file"; then
            suite_results+=("${GREEN}✓${NC} $name")
            ((total_passed++)) || true
        else
            suite_results+=("${RED}✗${NC} $name")
            ((total_failed++)) || true
        fi
        
        echo ""
    done
    
    # Print summary
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║           Test Summary                 ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}Test Suites:${NC}"
    for result in "${suite_results[@]}"; do
        echo -e "  $result"
    done
    
    echo ""
    echo -e "${BOLD}Overall Results:${NC}"
    echo -e "  Total Suites: $((total_passed + total_failed))"
    echo -e "  ${GREEN}Passed: $total_passed${NC}"
    echo -e "  ${RED}Failed: $total_failed${NC}"
    
    # Calculate duration
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    echo -e "  Duration: ${DURATION}s"
    
    echo ""
    
    # Exit status
    if [ $total_failed -eq 0 ]; then
        echo -e "${BOLD}${GREEN}✓ All test suites passed!${NC}"
        return 0
    else
        echo -e "${BOLD}${RED}✗ Some test suites failed!${NC}"
        return 1
    fi
}

# Test individual file
test_individual() {
    local test="$1"
    
    # Map test names to files
    case "$test" in
        header)
            run_bats_test "Header Function Tests" "$TEST_DIR/test_header.bats"
            ;;
        symlink)
            run_bats_test "Symlink Tests" "$TEST_DIR/test_symlink.bats"
            ;;
        deploy)
            run_bats_test "Deploy Script Tests" "$TEST_DIR/test_deploy.bats"
            ;;
        syntax)
            run_bats_test "Syntax Tests" "$TEST_DIR/test_syntax.bats"
            ;;
        *.bats)
            # Direct bats file
            if [ -f "$TEST_DIR/$test" ]; then
                run_bats_test "$(basename "$test" .bats) Tests" "$TEST_DIR/$test"
            elif [ -f "$test" ]; then
                run_bats_test "$(basename "$test" .bats) Tests" "$test"
            else
                echo -e "${RED}Error: Test file not found: $test${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Unknown test: $test${NC}"
            echo "Available tests: header, symlink, deploy, syntax"
            echo "Or specify a .bats file directly"
            exit 1
            ;;
    esac
}

# Run tests in CI mode (with TAP output)
run_ci_mode() {
    echo "# Running in CI mode with TAP output"
    
    # Ensure Bats is installed
    install_bats_if_needed
    
    # Run all tests with TAP format
    for test_file in "$TEST_DIR"/*.bats; do
        if [ -f "$test_file" ]; then
            "$BATS_BIN" --tap "$test_file"
        fi
    done
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS] [TEST]"
    echo ""
    echo "Run dotfiles test suite using Bats"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo "  -c, --ci       Run in CI mode (TAP output)"
    echo "  --tap          Output TAP format"
    echo ""
    echo "Tests:"
    echo "  header         Run header.sh function tests"
    echo "  symlink        Run symlink functionality tests"
    echo "  deploy         Run deploy script tests"
    echo "  syntax         Run syntax and linting tests"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 header             # Run only header tests"
    echo "  $0 test_header.bats   # Run specific test file"
    echo "  $0 --ci               # Run in CI mode"
}

# Main
main() {
    local ci_mode=false
    local tap_mode=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            -c|--ci)
                ci_mode=true
                shift
                ;;
            --tap)
                tap_mode=true
                shift
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Run in CI mode if requested
    if [ "$ci_mode" = true ]; then
        run_ci_mode
        exit $?
    fi
    
    print_header
    check_prerequisites
    install_bats_if_needed
    
    if [ $# -eq 0 ]; then
        # Run all tests
        run_all_tests
    else
        # Run specific test
        test_individual "$1"
    fi
}

# Make script executable
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi