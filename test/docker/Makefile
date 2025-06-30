# Makefile for Docker-based dotfiles testing

.PHONY: test test-all test-ubuntu test-archlinux shell clean help

# Default test
test: ## Run test with current environment settings
	docker compose run --rm test

# Test all combinations
test-all: ## Run all test combinations
	@echo "Testing all OS and installation method combinations..."
	@$(MAKE) test-ubuntu-remote
	@$(MAKE) test-ubuntu-local
	@$(MAKE) test-archlinux-remote
	@$(MAKE) test-archlinux-local

# Ubuntu tests
test-ubuntu: test-ubuntu-remote test-ubuntu-local ## Run all Ubuntu tests

test-ubuntu-remote: ## Test Ubuntu with remote installation
	OS=ubuntu INSTALL_METHOD=remote docker compose run --rm test

test-ubuntu-local: ## Test Ubuntu with local installation
	OS=ubuntu INSTALL_METHOD=local docker compose run --rm test

# Arch Linux tests
test-archlinux: test-archlinux-remote test-archlinux-local ## Run all Arch Linux tests

test-archlinux-remote: ## Test Arch Linux with remote installation
	OS=archlinux INSTALL_METHOD=remote docker compose run --rm test

test-archlinux-local: ## Test Arch Linux with local installation
	OS=archlinux INSTALL_METHOD=local docker compose run --rm test

# Interactive shell
shell: ## Start interactive shell for debugging
	docker compose run --rm shell

shell-ubuntu: ## Start Ubuntu interactive shell
	OS=ubuntu docker compose run --rm shell

shell-archlinux: ## Start Arch Linux interactive shell
	OS=archlinux docker compose run --rm shell

# Build images
build: ## Build all Docker images
	OS=ubuntu docker compose build test
	OS=archlinux docker compose build test

build-ubuntu: ## Build Ubuntu Docker image
	OS=ubuntu docker compose build test

build-archlinux: ## Build Arch Linux Docker image
	OS=archlinux docker compose build test

build-clean: ## Build all images without cache
	OS=ubuntu docker compose build --no-cache test
	OS=archlinux docker compose build --no-cache test

# Cleanup
clean: ## Remove all containers and images
	docker compose down --rmi all --volumes --remove-orphans

clean-containers: ## Remove all containers
	docker compose down --volumes --remove-orphans

# Logs
logs: ## Show logs from last test run
	docker compose logs

# Help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
