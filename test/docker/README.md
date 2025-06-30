# Docker Tests for Dotfiles

This directory contains Docker-based tests for the dotfiles installation process.

## Overview

The Docker tests allow you to test the installation process in clean, isolated environments for different operating systems without affecting your local machine.

## Files

- `Dockerfile.ubuntu` - Ubuntu test environment
- `Dockerfile.archlinux` - Arch Linux test environment
- `test_install.sh` - Test script that runs inside containers
- `docker compose.yml` - Docker Compose configuration
- `.env.example` - Example environment variables
- `run-tests.sh` - Convenience script for running tests
- `Makefile` - Make targets for common test scenarios
- `README.md` - This file

## Prerequisites

- Docker installed and running
- Docker Compose
- Make (optional, for using Makefile)

## Quick Start

### Using Make (Recommended)

```bash
# Show all available commands
make help

# Run all tests
make test-all

# Run specific OS tests
make test-ubuntu
make test-archlinux

# Run specific combination
make test-ubuntu-remote
make test-ubuntu-local

# Start interactive shell
make shell
make shell-ubuntu
make shell-archlinux

# Clean up
make clean
```

### Using Environment Variables

```bash
# Copy example environment file
cp .env.example .env

# Edit .env to set your preferences
# OS=ubuntu
# INSTALL_METHOD=remote
# RUN_CLEANUP=false

# Run test with current .env settings
docker compose run --rm test
```

### Using the Convenience Script

```bash
# Run with defaults (ubuntu, remote)
./run-tests.sh

# Run specific OS and method
./run-tests.sh ubuntu local
./run-tests.sh archlinux remote

# Run with cleanup
./run-tests.sh ubuntu remote --cleanup
```

### Direct Docker Compose Usage

```bash
# Run test with environment variables
OS=ubuntu INSTALL_METHOD=remote docker compose run --rm test
OS=archlinux INSTALL_METHOD=local docker compose run --rm test

# Use predefined services (for backward compatibility)
docker compose run --rm ubuntu-remote
docker compose run --rm ubuntu-local
docker compose run --rm archlinux-remote
docker compose run --rm archlinux-local

# Interactive shell for debugging
OS=ubuntu docker compose run --rm shell
```

## Test Types

1. **Remote Installation Test** - Tests the one-liner installation from GitHub
2. **Local Installation Test** - Tests cloning and installing from local repository
3. **Cleanup Test** - Tests the uninstallation process

## Adding New Tests

To add tests for a new OS:

1. Create a new Dockerfile (e.g., `Dockerfile.debian`)
2. Add the service to `docker compose.yml`
3. Update this README

## Environment Variables

The following environment variables can be used to configure tests:

- `OS` - Operating system to test (`ubuntu` or `archlinux`), default: `ubuntu`
- `INSTALL_METHOD` - Installation method (`remote` or `local`), default: `remote`
- `RUN_CLEANUP` - Run cleanup after tests (`true` or `false`), default: `false`

## Docker Compose Services

The `docker compose.yml` defines the following services:

- `test` - Main test service (configurable via environment variables)
- `ubuntu-remote` - Ubuntu with remote installation
- `ubuntu-local` - Ubuntu with local installation
- `archlinux-remote` - Arch Linux with remote installation
- `archlinux-local` - Arch Linux with local installation
- `shell` - Interactive shell for debugging

## Troubleshooting

### Build Issues

If tests fail due to network issues, try rebuilding without cache:
```bash
make build  # Build all images
docker compose build --no-cache test
```

### Debugging Failed Tests

Start an interactive shell:
```bash
# Using make
make shell-ubuntu
make shell-archlinux

# Using docker compose
OS=ubuntu docker compose run --rm shell
```

### Cleanup

Remove all containers and images:
```bash
make clean  # Remove everything
make clean-containers  # Remove only containers
```

### View Logs

```bash
make logs
# or
docker compose logs
```

## CI/CD Integration

These Docker tests are integrated with GitHub Actions. The workflow:
1. Builds Docker images for each OS
2. Runs tests with different installation methods
3. Executes Bats tests inside containers
4. Reports results

See `.github/workflows/test.yml` for details.
