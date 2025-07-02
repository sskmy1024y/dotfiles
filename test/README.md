# Dotfiles Test Suite

This directory contains comprehensive tests for the dotfiles installation scripts using Bats (Bash Automated Testing System).

## Overview

The test suite ensures that the dotfiles installation process works correctly across different platforms and scenarios. It includes unit tests, integration tests, and end-to-end tests, all written using the Bats testing framework.

## What is Bats?

[Bats](https://github.com/bats-core/bats-core) is a TAP-compliant testing framework for Bash. It provides a simple way to verify that your shell scripts behave as expected.

## Test Structure

```
test/
├── bats/                    # Bats installation (auto-generated)
├── docker/                  # Docker-based E2E tests
│   ├── Dockerfile.ubuntu
│   ├── Dockerfile.archlinux
│   ├── docker-compose.yml
│   └── test_install.sh
├── install_bats.sh          # Bats installer script
├── run_tests.sh            # Main test runner
├── test_helper.bash        # Common test helpers and utilities
├── test_header.bats        # Unit tests for header.sh functions
├── test_symlink.bats       # Tests for symlink functionality
├── test_deploy.bats        # Tests for deploy script
├── test_syntax.bats        # Syntax and linting tests
└── README.md               # This file
```

## Installing Bats

The test suite will automatically install Bats when you run tests for the first time. You can also install it manually:

```bash
cd ~/.dotfiles/test
./install_bats.sh
```

This will clone Bats and its dependencies into the `test/bats/` directory.

## Running Tests

### Run All Tests
```bash
cd ~/.dotfiles
make test

# Or directly:
cd ~/.dotfiles/test
./run_tests.sh
```

### Run Specific Test Suite
```bash
# Run only header function tests
./run_tests.sh header

# Run only symlink tests
./run_tests.sh symlink

# Run only deploy tests
./run_tests.sh deploy

# Run only syntax tests
./run_tests.sh syntax
```

### Run Individual Bats File
```bash
# Using the test runner
./run_tests.sh test_header.bats

# Or directly with Bats
./bats test_header.bats
```

### CI Mode (TAP Output)
```bash
# Run all tests with TAP output
./run_tests.sh --ci

# Or specific test
./bats --tap test_header.bats
```

## Test Categories

### 1. Unit Tests (`test_header.bats`)
Tests individual functions from `etc/lib/header.sh`:
- `detect_os()` - OS detection
- `is_exists()` - Command existence check
- `has()` - Type check
- `symlink()` - Symlink creation
- `wild_symlink()` - Wildcard symlink creation
- Color output functions

### 2. Integration Tests (`test_symlink.bats`, `test_deploy.bats`)
Tests the integration of multiple components:
- Symlink creation and management
- Deploy script functionality
- Directory creation with proper permissions
- Error handling and edge cases

### 3. Code Quality Tests (`test_syntax.bats`)
Ensures code quality and consistency:
- Bash syntax validation
- ShellCheck linting (if installed)
- Common issue detection (hardcoded paths, missing error handling)
- Makefile validation

### 4. E2E Tests (`docker/`)
Full installation tests in isolated environments:
- Ubuntu installation test
- Arch Linux installation test
- Remote installation (one-liner)
- Local installation (git clone + make)
- Bats tests execution in Docker

## Writing Bats Tests

### Basic Test Structure
```bash
#!/usr/bin/env bats

load test_helper

setup() {
    # Run before each test
    setup_test_dir
}

teardown() {
    # Run after each test
    teardown_test_dir
}

@test "description of what is being tested" {
    # Test implementation
    run some_command
    assert_success
    assert_output "expected output"
}
```

### Common Assertions
```bash
# Check command success/failure
assert_success
assert_failure

# Check output
assert_output "exact text"
assert_output --partial "partial text"
assert_line "text on specific line"

# Check files/directories
assert_file_exists "/path/to/file"
assert_dir_exists "/path/to/dir"
assert_link_exists "/path/to/symlink"
assert_symlink_to "/link" "/target"

# Skip tests
skip "reason for skipping"
skip_if_os "darwin"  # Skip on macOS
skip_unless_os "ubuntu"  # Only run on Ubuntu
skip_if_missing "shellcheck"  # Skip if command not found
```

### Test Helpers

The `test_helper.bash` file provides common utilities:
- `setup_test_dir()` - Creates temporary test directory
- `teardown_test_dir()` - Cleans up test directory
- `create_test_file()` - Creates test files
- `command_exists()` - Checks if command exists
- `mock_command()` - Creates command mocks
- `get_permissions()` - Gets file permissions (cross-platform)

## Prerequisites

### Required
- Bash 3.2+ (Bash 4.0+ recommended)
- Git

### Optional
- ShellCheck (for linting tests)
- Docker & Docker Compose (for E2E tests)

### Installing ShellCheck
```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt-get install shellcheck

# Arch Linux
sudo pacman -S shellcheck
```

## CI/CD Integration

The test suite is integrated with GitHub Actions. Tests run automatically on:
- Push to master/main/develop branches
- Pull requests
- Manual workflow dispatch

The CI pipeline includes:
- Bats tests on Ubuntu and macOS
- Individual test suites in parallel
- Docker-based E2E tests
- Syntax and linting checks

See `.github/workflows/test.yml` for CI configuration.

## Docker Testing

### Running Bats Tests in Docker

The test suite includes dedicated Docker support for running Bats tests in an isolated environment:

```bash
# Quick start - run all Bats tests in Docker
make test-bats

# Run in CI mode (TAP output)
make test-bats-ci

# Open interactive shell for debugging
make test-bats-shell
```

### Docker Bats Commands

From the `test/docker` directory:

```bash
# Run all Bats tests
make bats

# Run specific test file
make bats-file TEST_FILE=test/test_syntax.bats

# Shortcuts for specific test suites
make bats-syntax    # Syntax and linting tests
make bats-header    # Header function tests
make bats-symlink   # Symlink tests
make bats-deploy    # Deploy script tests

# Build the Bats Docker image
make build-bats
```

### Full Installation Tests

Run complete installation tests in Docker containers:

```bash
# Run all Docker tests
make test-docker

# Run specific OS tests
make test-docker-ubuntu
make test-docker-archlinux

# Or manually
cd test/docker
docker compose up --build

# Run specific OS/install combination
docker compose up ubuntu-remote
docker compose up archlinux-local
```

See [test/docker/README_BATS.md](docker/README_BATS.md) for detailed Docker Bats testing documentation.

## Troubleshooting

### Bats not found
```bash
# Reinstall Bats
./install_bats.sh
```

### Tests fail on macOS
Some tests use platform-specific commands. The test suite handles this with:
- `skip_if_os` / `skip_unless_os` helpers
- Platform detection in `get_permissions()`

### Permission errors
```bash
# Ensure scripts are executable
chmod +x test/*.sh test/bats
```

### Docker tests fail
1. Ensure Docker is running
2. Check internet connectivity
3. Rebuild without cache:
   ```bash
   cd test/docker
   docker compose build --no-cache
   ```

## Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Always clean up temporary files
3. **Assertions**: Use specific assertions over generic ones
4. **Skipping**: Skip tests gracefully when dependencies are missing
5. **Documentation**: Add descriptive test names

## Contributing

When adding new features to dotfiles:
1. Write corresponding Bats tests
2. Ensure all tests pass locally
3. Update this README if needed
4. Submit PR with passing CI checks

## Resources

- [Bats Documentation](https://bats-core.readthedocs.io/)
- [Bats Assert Library](https://github.com/bats-core/bats-assert)
- [Bats File Library](https://github.com/bats-core/bats-file)
- [TAP Protocol](https://testanything.org/)
