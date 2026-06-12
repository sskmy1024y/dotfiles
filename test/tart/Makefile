.DEFAULT_GOAL := help

TART_DIR  := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
BIN       := $(TART_DIR)/bin

.PHONY: help prepare oneliner git-clone full shell clean clean-all check

help: ## Show available targets
	@awk 'BEGIN {FS=":.*?## "}; /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check: ## Verify Tart and required tools are installed
	@$(BIN)/tart-prepare --help > /dev/null && echo "[+] tart-helpers OK"
	@command -v tart    > /dev/null && echo "[+] tart    found" || (echo "[-] tart    missing: brew install cirruslabs/cli/tart"; exit 1)
	@command -v sshpass > /dev/null && echo "[+] sshpass found" || (echo "[-] sshpass missing: brew install hudochenkov/sshpass/sshpass"; exit 1)
	@command -v rsync   > /dev/null && echo "[+] rsync   found" || (echo "[-] rsync   missing"; exit 1)

prepare: ## Pull vanilla macOS image and prepare the base VM (first-time setup; 30-60 min)
	$(BIN)/tart-prepare

oneliner: ## Scenario 01: curl one-liner against a fresh VM (reproduces issue #1)
	$(BIN)/tart-run 01-oneliner-remote

git-clone: ## Scenario 02: local repo + make install (reproduces issue #2)
	$(BIN)/tart-run 02-git-clone-local

full: ## Scenario 03: full install (deploy + init + deep)
	$(BIN)/tart-run 03-full-install

shell: ## Boot a fresh VM and open an SSH shell (interactive debugging)
	$(BIN)/tart-run --shell

keep-oneliner: ## Like 'oneliner' but leaves the VM around for inspection
	$(BIN)/tart-run --keep 01-oneliner-remote

keep-git-clone: ## Like 'git-clone' but leaves the VM around for inspection
	$(BIN)/tart-run --keep 02-git-clone-local

keep-full: ## Like 'full' but leaves the VM around for inspection
	$(BIN)/tart-run --keep 03-full-install

clean: ## Destroy all ephemeral test VMs (keeps base)
	$(BIN)/tart-destroy

clean-all: ## Destroy all test VMs AND the base VM (full reset)
	$(BIN)/tart-destroy --all
