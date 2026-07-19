# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Makefile Commands
- `make install` - Complete setup (deploy + init)
- `make deploy` - Create symbolic links to home directory
- `make init` - Install packages and setup environment
- `make deep` - Install advanced tools and fonts
- `make update` - Update dotfiles from repository
- `make clean` - Remove dotfiles and repository
- `make help` - Show all available commands

### Installation Methods
1. **One-liner remote install:**
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap)"
   ```

2. **With package installation:**
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap)" -s init
   ```

3. **Manual clone and install:**
   ```bash
   git clone https://github.com/sskmy1024y/dotfiles.git $HOME/.dotfiles
   cd $HOME/.dotfiles
   make install
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
- `etc/scripts/deploy` - Main deployment script that creates all symbolic links
- `etc/scripts/init` - Runs numbered installation scripts from `install.d/`
- `etc/scripts/install.d/` - Numbered installer steps (00 packages, 10 brew, 20 anyenv, 21 node, 22 python, 30 tmux/TPM, ...)
- `etc/scripts/deep.d/` - Advanced setup scripts including font installation
- `etc/lib/header.sh` - Shared functions for symlink creation, OS detection, and colored output
- `etc/lib/macos.sh` - macOS-only helpers: `ensure_xcode_clt` (non-interactive CLT install via `softwareupdate`), `ensure_homebrew` (idempotent brew bootstrap, fixes PATH), `brew_prefix` / `brew_on_path`. Sourced by `install.d/00_package.sh`, `install.d/10_brew.sh`, and `deep.d/{97_applications,98_font}.sh` — any script that needs `brew` on PATH in the current shell must source this.

### Install ordering on macOS
1. `deploy` creates symlinks. **TPM (tmux plugin manager) clone is deferred** here if `git` is missing — it runs later from `install.d/30_tmux.sh` after git is installed via brew.
2. `init` runs `install.d/*.sh` in numeric order. On macOS this means `00_package.sh` ensures Xcode CLT + brew + core packages, `10_brew.sh` applies the `Brewfile`, then `30_tmux.sh` clones TPM.

The one-liner `etc/bootstrap` downloads the GitHub **tarball** (`master.tar.gz`) — NOT the zip — so it can be piped straight into `tar xz` without needing `unzip` on a fresh macOS. After the repository is present, it delegates to `etc/setup`.

### `make deep` notes (macOS)
- `make deep` runs `etc/scripts/deep.d/*.sh` via `find | sort | bash`. Bash reads each filename from stdin as a command; non-zero exit from an early script does **not** stop later scripts, but the LAST script's exit code is what `make` sees.
- `deep.d/97_applications.sh` MUST call `ensure_homebrew` / `brew_on_path` from `macos.sh`. A fresh `make deep` shell hasn't sourced `~/.zprofile`, so `brew` isn't on PATH and naive `is_exists brew` checks return false.
- `deep.d/98_font.sh` installs **Cica only** — by downloading the upstream zip from `miiton/Cica` releases (Cica is already pre-patched with Nerd Font glyphs, so no `fontforge` / `nerd-fonts` / `font-patcher` is involved). Other Nerd Fonts (Meslo, JetBrains Mono, Hack, FiraCode) are installed via casks in `Brewfile`. The script also falls back to `warn + exit 0` if the GitHub API is rate-limited so a single font failure doesn't kill `make deep`.
- `deep.d/99_others.sh`: `sudo spctl --master-disable` was deprecated in macOS Sequoia (15.x) — it prints `Globally disabling the assessment system needs to be confirmed in System Settings.` and exits non-zero. The script tolerates this with a warning so `make deep` doesn't abort.

### Key Files
- `Makefile` - Main entry point for all operations
- `etc/scripts/install.d/Brewfile` - Homebrew package definitions for macOS
- `config/zsh/.zshrc` - Main Zsh configuration that sources modular files
- `config/tmux/.tmux.conf` - Tmux configuration with TPM plugin management

### Installation Flow
1. Clone repository to `~/.dotfiles`
2. Run `make deploy` to create symbolic links
3. Run `make init` to install packages via numbered scripts in `install.d/`
4. Optional: Run `make deep` for advanced tools and fonts

## Testing Requirements

### After Making Changes
- **Always run tests after modifying files**: Execute both `make bats` and `make test-docker` to ensure changes don't break existing functionality
- `make test-bats` - Runs Bats test suite for shell scripts
- `make test-docker` - Tests deployment in Docker containers for different Linux distributions

### Test Infrastructure Layout
- `test/run_tests.sh` - Top-level test runner (legacy + TAP output)
- `test/bats/` - Vendored Bats core; do not edit by hand
- `test/test_*.bats` - Bats test files for individual installer components
- `test/docker/` - Container-based Linux tests (Ubuntu, Arch Linux)
- `test/docker/Dockerfile.macos` - **Fake** macOS env (Ubuntu + `OSTYPE=darwin`); smoke test only
- `test/tart/` - **Real** macOS VM tests via Tart on Apple Silicon (see below)

### Docker Linux tests: local vs remote
- The `*-local` targets (`test-ubuntu-local` / `test-archlinux-local` in `test/docker/Makefile`) must use the compose services `ubuntu-local` / `archlinux-local`, which **mount the working tree** (`../../` → `~/dotfiles-local`) — uncommitted changes ARE tested. (Fixed 2026-07: they previously called the unmounted `test` service, so `test_install.sh` silently fell back to cloning GitHub master and local changes were never exercised.)
- The `*-remote` targets run the `curl | bash` bootstrap against GitHub `master` — local changes are NOT covered until pushed.

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
- `make test-mac-tart-full` - Full `deploy + init + deep` pipeline
- `make test-mac-tart-shell` - Boot a fresh VM and drop into SSH for debugging
- `make test-mac-tart-clean` - Destroy ephemeral test VMs (keeps base)
- `make test-mac-tart-clean-all` - Destroy ALL Tart VMs including base

All targets delegate to `test/tart/Makefile`. See `test/tart/README.md` for
scenario contract, env-var knobs (`TART_BASE_IMAGE`, `TART_SSH_TIMEOUT`,
`ONELINER_URL`, ...), and troubleshooting.

> **Note**: `make test-mac-local` (Docker-based) is a fake-macOS smoke test
> only. Use Tart for trustworthy macOS validation.
