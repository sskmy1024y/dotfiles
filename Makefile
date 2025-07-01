DOTPATH    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*) bin config
EXCLUSIONS := .DS_Store .git .github .gitignore .vscode
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

.PHONY: test

all:

update: ## Fetch changes for this repo
	git pull origin master

deploy: ## Create symlink to home directory
	@echo '==> Start to deploy dotfiles to home directory.'
	@echo ''
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/scripts/deploy

init: ## Setup environment settings
	@echo '==> Start to install app using pkg manager.'
	@echo ''
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/scripts/init

deep: ## Setup more finicky settings
	@echo '==> Start to install a variety of tools.'
	@echo ''
	@find $(DOTPATH)/etc/scripts/deep.d -name "[0-9][0-9]*.sh" | sort | bash

install: deploy init ## Run make deploy, init
	@exec $$SHELL

check: ## Check if it is ready to install
	@echo 'PATH:' $(DOTPATH)
	@echo 'TARGET:' $(DOTFILES)

clean: ## Remove dotfiles and this repo
	@echo 'Remove dot files in your home directory...'
	@-$(foreach val, $(DOTFILES), rm -vrf $(HOME)/$(val);)
	-rm -rf $(DOTPATH)

test: ## Run test suite
	@echo '==> Running test suite'
	@bash $(DOTPATH)/test/run_tests.sh

test-rebuild: ## Rebuild Docker images and run tests
	@echo '==> Rebuilding Docker images and running tests'
	@cd $(DOTPATH)/test/docker && $(MAKE) build-clean

test-docker: ## Run Docker-based tests
	@echo '==> Running Docker tests'
	@cd $(DOTPATH)/test/docker && $(MAKE) test-all

test-docker-ubuntu: ## Run Docker tests for Ubuntu
	@echo '==> Running Docker tests for Ubuntu'
	@cd $(DOTPATH)/test/docker && $(MAKE) test-ubuntu

test-docker-archlinux: ## Run Docker tests for Arch Linux
	@echo '==> Running Docker tests for Arch Linux'
	@cd $(DOTPATH)/test/docker && $(MAKE) test-archlinux

test-bats: ## Run Bats tests in Docker (both Ubuntu and Arch Linux)
	@echo '==> Running Bats tests in Docker'
	@cd $(DOTPATH)/test/docker && $(MAKE) bats

test-bats-ubuntu: ## Run Bats tests in Docker (Ubuntu only)
	@echo '==> Running Bats tests in Ubuntu Docker'
	@cd $(DOTPATH)/test/docker && $(MAKE) bats-ubuntu

test-bats-archlinux: ## Run Bats tests in Docker (Arch Linux only)
	@echo '==> Running Bats tests in Arch Linux Docker'
	@cd $(DOTPATH)/test/docker && $(MAKE) bats-archlinux

test-bats-ci: ## Run Bats tests in Docker CI mode (both OS)
	@echo '==> Running Bats tests in Docker (CI mode)'
	@cd $(DOTPATH)/test/docker && $(MAKE) bats-ci

test-mac-local: ## Run tests in macOS Docker container
	@echo '==> Running tests in macOS Docker container'
	@cd $(DOTPATH)/test/docker && $(MAKE) test-mac-local

help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
