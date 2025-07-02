# Makefile for Docker-based dotfiles testing

# Set platform for Apple Silicon compatibility
export DOCKER_DEFAULT_PLATFORM := linux/amd64

.PHONY: test test-all test-ubuntu test-archlinux shell clean help \
        bats bats-ubuntu bats-archlinux bats-ci bats-test \
        build build-ubuntu build-archlinux build-clean \
        clean-containers logs shell-ubuntu shell-archlinux

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

# Bats tests
bats: ## Run all Bats tests (use OS=ubuntu/archlinux/all, default: all)
	@if [ "$(OS)" = "ubuntu" ]; then \
		$(MAKE) bats-ubuntu; \
	elif [ "$(OS)" = "archlinux" ]; then \
		$(MAKE) bats-archlinux; \
	else \
		$(MAKE) bats-ubuntu bats-archlinux; \
	fi

bats-ubuntu: ## Run all Bats tests on Ubuntu
	OS=ubuntu docker compose run --rm bats

bats-archlinux: ## Run all Bats tests on Arch Linux
	OS=archlinux docker compose run --rm bats

bats-ci: ## Run Bats tests in CI mode (use OS=ubuntu/archlinux/all, default: all)
	@if [ "$(OS)" = "ubuntu" ]; then \
		OS=ubuntu CI=true docker compose run --rm bats; \
	elif [ "$(OS)" = "archlinux" ]; then \
		OS=archlinux CI=true docker compose run --rm bats; \
	else \
		OS=ubuntu CI=true docker compose run --rm bats; \
		OS=archlinux CI=true docker compose run --rm bats; \
	fi

# Run specific test file or suite
# Usage: make bats-test TEST=syntax OS=ubuntu
#        make bats-test TEST=test/test_header.bats OS=archlinux
#        make bats-test TEST=deploy (runs on both OS)
bats-test: ## Run specific test (use TEST=name/path OS=ubuntu/archlinux/all)
	@if [ -z "$(TEST)" ]; then \
		echo "Error: TEST parameter required. Example: make bats-test TEST=syntax"; \
		exit 1; \
	fi; \
	if [ -f "$(TEST)" ]; then \
		TEST_FILE="$(TEST)"; \
	elif [ -f "test/$(TEST)" ]; then \
		TEST_FILE="test/$(TEST)"; \
	elif [ -f "test/test_$(TEST).bats" ]; then \
		TEST_FILE="test/test_$(TEST).bats"; \
	else \
		echo "Error: Test file not found: $(TEST)"; \
		exit 1; \
	fi; \
	if [ "$(OS)" = "ubuntu" ]; then \
		echo "Running $$TEST_FILE on Ubuntu..."; \
		OS=ubuntu TEST_FILE=$$TEST_FILE docker compose run --rm bats; \
	elif [ "$(OS)" = "archlinux" ]; then \
		echo "Running $$TEST_FILE on Arch Linux..."; \
		OS=archlinux TEST_FILE=$$TEST_FILE docker compose run --rm bats; \
	else \
		echo "Running $$TEST_FILE on Ubuntu..."; \
		OS=ubuntu TEST_FILE=$$TEST_FILE docker compose run --rm bats; \
		echo "Running $$TEST_FILE on Arch Linux..."; \
		OS=archlinux TEST_FILE=$$TEST_FILE docker compose run --rm bats; \
	fi

# macOS test
test-mac-local: ## Test macOS using local Docker container
	@echo "Testing macOS with local Docker container..."
	@docker compose -f docker-compose.macos.yml up --build --abort-on-container-exit

# Logs
logs: ## Show logs from last test run
	docker compose logs

# Help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
