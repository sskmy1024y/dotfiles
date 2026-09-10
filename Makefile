DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help

.PHONY: test bats test-bats test-rebuild test-docker test-docker-all \
	test-docker-ubuntu test-docker-archlinux test-bats-docker \
	test-bats-ubuntu test-bats-archlinux test-bats-ci test-mac-local \
	test-mac-tart-check test-mac-tart-prepare test-mac-tart-oneliner \
	test-mac-tart-git test-mac-tart-full test-mac-tart-shell \
	test-mac-tart-clean test-mac-tart-clean-all help

test: ## Run the local Bats test suite
	@bash $(DOTPATH)/test/run_tests.sh --ci

bats: test ## Alias for the local Bats test suite

test-bats: test ## Alias for the local Bats test suite

test-rebuild: ## Rebuild Docker images without cache
	@$(MAKE) -C $(DOTPATH)/test/docker build-clean

test-docker: ## Run the default installation integration test on Ubuntu
	@SKIP_BATS_TESTS=true $(MAKE) -C $(DOTPATH)/test/docker test-ubuntu-local

test-docker-all: ## Run installation integration tests on Ubuntu and Arch Linux
	@SKIP_BATS_TESTS=true $(MAKE) -C $(DOTPATH)/test/docker test-ubuntu-local test-archlinux-local

test-docker-ubuntu: ## Test the current working tree on Ubuntu
	@$(MAKE) -C $(DOTPATH)/test/docker test-ubuntu-local

test-docker-archlinux: ## Test the current working tree on Arch Linux
	@$(MAKE) -C $(DOTPATH)/test/docker test-archlinux-local

test-bats-docker: ## Run Bats in Ubuntu and Arch Linux containers
	@$(MAKE) -C $(DOTPATH)/test/docker bats

test-bats-ubuntu: ## Run Bats in an Ubuntu container
	@$(MAKE) -C $(DOTPATH)/test/docker bats-ubuntu

test-bats-archlinux: ## Run Bats in an Arch Linux container
	@$(MAKE) -C $(DOTPATH)/test/docker bats-archlinux

test-bats-ci: ## Run Bats in CI mode in both Linux containers
	@$(MAKE) -C $(DOTPATH)/test/docker bats-ci

test-mac-local: ## Run the fake-macOS Docker smoke test
	@$(MAKE) -C $(DOTPATH)/test/docker test-mac-local

test-mac-tart-check: ## Verify Tart and its dependencies are installed
	@$(MAKE) -C $(DOTPATH)/test/tart check

test-mac-tart-prepare: ## Prepare the vanilla macOS Tart base VM
	@$(MAKE) -C $(DOTPATH)/test/tart prepare

test-mac-tart-oneliner: ## Test the remote one-liner in a clean macOS VM
	@$(MAKE) -C $(DOTPATH)/test/tart oneliner

test-mac-tart-git: ## Test the local working tree in a clean macOS VM
	@$(MAKE) -C $(DOTPATH)/test/tart git-clone

test-mac-tart-full: ## Test the full Terraform installer in a clean macOS VM
	@$(MAKE) -C $(DOTPATH)/test/tart full

test-mac-tart-shell: ## Open a shell in a fresh macOS Tart VM
	@$(MAKE) -C $(DOTPATH)/test/tart shell

test-mac-tart-clean: ## Destroy ephemeral Tart VMs
	@$(MAKE) -C $(DOTPATH)/test/tart clean

test-mac-tart-clean-all: ## Destroy all Tart VMs, including the base
	@$(MAKE) -C $(DOTPATH)/test/tart clean-all

help: ## Show available commands
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
