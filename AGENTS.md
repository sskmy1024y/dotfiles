# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Common Commands

### CLI Commands
- `dotfiles install` - Apply configuration, managed packages, and OS settings
- `dotfiles sync` - Sync configuration without packages or OS settings
- `dotfiles runtimes` - Install anyenv, Node.js, and Python
- `dotfiles extras` - Install optional applications, Cica, and macOS integration
- `dotfiles plan` / `check` / `status` - Inspect the managed setup
- `dotfiles update` / `clean` - Update the checkout or destroy Terraform resources

The root Makefile contains test and VM harness targets only.

### Installation Methods
1. **One-liner remote install:**
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap)"
   ```

2. **With package installation:**
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap)" -- --yes
   ```

3. **Manual clone and install:**
   ```bash
   git clone https://github.com/sskmy1024y/dotfiles.git $HOME/.dotfiles
   cd $HOME/.dotfiles
   ./bin/dotfiles install
   ```

## Repository Architecture

### Directory Structure
- `bin/` - Custom executable scripts symlinked to `~/.local/bin`
- `config/` - Configuration files organized by application (git, tmux, zsh, ssh, iterm)
- `etc/scripts/` - Installation and deployment scripts
- `etc/lib/` - Shared library functions for scripts
- `doc/` - Documentation files

### Configuration Management
- **Zsh**: Modular configuration with numbered files (00-42) for loading order
  - Uses Zinit as plugin manager (migrating from Zplug - see `feat/zinit` branch)
  - Files in `config/zsh/` are symlinked to `~/.zsh/`
  
- **Deployment Strategy**: Uses symbolic links to maintain live connection between repository and home directory configs
- **Cross-platform**: Supports Ubuntu, Arch Linux, and macOS with OS detection in scripts

### Script Architecture
- `bin/dotfiles` - Only public operational CLI
- `etc/install` - Bootstrap requirements and Terraform orchestration
- `etc/scripts/runtimes/` - Explicit anyenv, Node.js, and Python components
- `etc/scripts/extras/` - Explicit optional application, Cica, and macOS components
- `config/homebrew/Brewfile` - Homebrew package manifest
- `etc/lib/header.sh` - Shared functions for symlink creation, OS detection, and colored output
- `etc/lib/macos.sh` - Shared Xcode CLT and Homebrew bootstrap helpers

### Installation flow
1. `etc/bootstrap` obtains the repository and invokes `dotfiles install`.
2. `etc/install` ensures required tools, installs `fzf` on Linux, and applies Terraform.
3. Terraform owns symlinks, the Linux SSH identity, Homebrew bundle, macOS defaults, and Tode integration.
4. `dotfiles runtimes` and `dotfiles extras` run only their explicit optional components.

The one-liner `etc/bootstrap` downloads the GitHub **tarball** (`master.tar.gz`) — NOT the zip — so it can be piped straight into `tar xz` without needing `unzip` on a fresh macOS.

### Key Files
- `bin/dotfiles` - Main entry point for all operations
- `config/homebrew/Brewfile` - Homebrew package definitions for macOS
- `config/zsh/.zshrc` - Main Zsh configuration that sources modular files
- `config/tmux/.tmux.conf` - Tmux configuration with TPM plugin management

### Installation Flow
1. Clone repository to `~/.dotfiles`
2. Run `./bin/dotfiles install`
3. Optionally run `dotfiles runtimes` or `dotfiles extras`

## Testing Requirements

### After Making Changes
- **Always run tests after modifying files**: Execute both `make bats` and `make test-docker` to ensure changes don't break existing functionality
- `make bats` / `make test-bats` - Runs the local Bats test suite
- `make test-docker` - Tests deployment in Docker containers for different Linux distributions

### Test Infrastructure Layout
- `test/run_tests.sh` - Top-level Bats/TAP test runner
- `test/bats/` - Vendored Bats core; do not edit by hand
- `test/test_*.bats` - Bats test files for individual installer components
- `test/docker/` - Container-based Linux tests (Ubuntu, Arch Linux)
- `test/docker/Dockerfile.macos` - **Fake** macOS env (Ubuntu + `OSTYPE=darwin`); smoke test only
- `test/tart/` - **Real** macOS VM tests via Tart on Apple Silicon (see below)

### Real macOS Testing via Tart (Apple Silicon host required)
For reproducing and fixing macOS-only failures (curl one-liner errors, missing
`git` at deploy time, hung `xcode-select --install`, etc.), use the Tart-based
clean-room VM harness under `test/tart/`. Each run starts from a vanilla
`ghcr.io/cirruslabs/macos-sequoia-vanilla` image — no leftover state from prior
attempts.

- `make test-mac-tart-check` - Verify `tart`, `sshpass`, `rsync` are installed
- `make test-mac-tart-prepare` - One-time: pull image + create `dotfiles-base` VM (30-60 min)
- `make test-mac-tart-oneliner` - Reproduce the `curl ... | bash` failure (#1)
- `make test-mac-tart-git` - Reproduce the `git not installed` failure (#2); uses your **local working tree** via rsync (no need to push)
- `make test-mac-tart-full` - Full `dotfiles install` pipeline
- `make test-mac-tart-shell` - Boot a fresh VM and drop into SSH for debugging
- `make test-mac-tart-clean` - Destroy ephemeral test VMs (keeps base)
- `make test-mac-tart-clean-all` - Destroy ALL Tart VMs including base

All targets delegate to `test/tart/Makefile`. See `test/tart/README.md` for
scenario contract, env-var knobs (`TART_BASE_IMAGE`, `TART_SSH_TIMEOUT`,
`ONELINER_URL`, ...), and troubleshooting.

> **Note**: `make test-mac-local` (Docker-based) is a fake-macOS smoke test
> only. Use Tart for trustworthy macOS validation.
