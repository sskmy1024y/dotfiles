<p align="center">
<img src="https://user-images.githubusercontent.com/16918590/129431439-e3a2f2e9-ebf8-4ef5-a8be-ead0d45d73b0.png" height="164px;" />
<h1 align="center">Dotfiles</h1>
<p align="center">
<img src="https://img.shields.io/badge/works%20on-Ubuntu-DD4814.svg" />
<img src="https://img.shields.io/badge/works%20on-ArchLinux-00AAD4.svg" />
<img src="https://img.shields.io/badge/works%20on-MacOS-lightgrey.svg" />
<a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</p>

## 🤔 What is this

This is a repository with my configuration files, those are verified on Linux / macOS.

Author: sskmy1024y  
Date: 2/Jul/2025 

## Directory structure

```sh
dotfiles/
 ├── bin/            # Useful command line scripts
 ├── config/         # Dotfiles
 │   ├── codex       # Codex global instructions
 │   ├── git         # Git configuration
 │   ├── iterm       # iTerm2 configuration
 │   ├── ssh         # SSH configuration
 │   ├── tode        # Tode and Ghostty integration (macOS)
 │   └── zsh         # Zsh shell configuration
 ├── doc/            # Document files
 ├── etc/
 │   ├── install     # Remote installer
 │   └── scripts     # Legacy helpers and Brewfile
 ├── terraform/      # Terraform entrypoint and modules
 ├── test/           # Test suite
 │   ├── bats        # Bats testing framework
 │   ├── docker      # Docker test environments
 │   └── *.bats      # Test files
```

## Setup

Run the installer from a clean machine:

```sh
curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/install.sh | sh
```

The POSIX `install.sh` entrypoint downloads the Bash bootstrap, obtains the
repository, installs the `dotfiles` command into `~/.local/bin`, and runs the
standard setup when no completed installation is detected. It requires `sh`,
`bash`, `tar`, and either `curl` or `wget`.

After the first setup, run `dotfiles` to open the interactive menu or select an
action directly:

```sh
dotfiles sync
dotfiles plan
dotfiles runtimes
dotfiles extras
dotfiles status
```

The installer offers to install missing bootstrap tools through the platform
package manager, including:

- `git`
- `terraform`
- `unzip` for the Terraform release archive
- `ssh-keygen` for the Linux GitHub identity
- `brew` when Homebrew bundle is enabled
- `defaults` when macOS defaults are enabled

If `terraform` is missing during a normal install, the installer attempts to
install it automatically. On macOS it uses Homebrew, installing Homebrew first
when necessary. On Linux it installs the Terraform release archive into
`~/.local/bin` when Homebrew is unavailable.

By default it obtains this repository at `~/.dotfiles`, initializes Terraform,
and applies the modules for symlinks, Homebrew, and macOS defaults. A successful
initial setup is recorded under `${XDG_STATE_HOME:-~/.local/state}/dotfiles`.

```sh
curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/install.sh | sh -s -- plan
curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/install.sh | sh -s -- install --yes
curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/install.sh | sh -s -- install --no-brew
```

For manual installation:

```bash
git clone https://github.com/sskmy1024y/dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
./bin/dotfiles install
```

The setup links `bin/dotfiles` to `~/.local/bin/dotfiles`. Make sure
`~/.local/bin` is on `PATH` before invoking it by name in the current shell.

### CLI commands

| Command | Purpose |
| --- | --- |
| `dotfiles install` | Standard setup: sync dotfiles, apply the Brewfile on macOS, and apply OS settings. |
| `dotfiles sync` | Sync dotfiles without applying the Brewfile or macOS defaults. |
| `dotfiles runtimes` | Optionally install anyenv, Node.js, and Python. |
| `dotfiles extras` | Optionally install extra applications, Cica, and advanced OS settings. |
| `dotfiles plan` | Preview Terraform-managed changes without applying them. |
| `dotfiles check` | Check installer requirements without changing the system. |
| `dotfiles status` | Show whether initial setup completed and run the requirements check. |
| `dotfiles update` | Pull repository changes with Git. |
| `dotfiles clean` | Destroy Terraform-managed links and settings while keeping the repository. |

The existing Make targets remain as compatibility wrappers. For example,
`make install`, `make deploy`, and `make runtimes` delegate to the corresponding
CLI commands. `make init` remains a deprecated alias for `dotfiles runtimes`.

### Options

```bash
--plan                 Run terraform plan only
--check                Check commands and repository presence only
--yes                  Apply without an interactive confirmation
--no-brew              Do not run brew bundle
--no-macos-defaults    Do not write macOS defaults
--no-1password-ssh     Do not link 1Password SSH config
```

### Environment variables

- `DOTPATH`: install path. Default: `~/.dotfiles`
- `DOTFILES_GITHUB`: git remote. Default: this repository
- `DOTFILES_BRANCH`: git branch. Default: `master`
- `DOTFILES_ASSUME_YES=1`: same as `--yes`
- `TERRAFORM_VERSION`: Terraform version for non-Homebrew installs

## Terraform modules

- `modules/symlink`: creates config and binary symlinks under `$HOME`
- `modules/brew`: runs `brew bundle` when `etc/scripts/install.d/Brewfile` changes
- `modules/macos_defaults`: writes macOS defaults and restarts Dock/Finder

Run Terraform directly when iterating locally:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Testing

The Bats and Docker test suites are available through the root Makefile:

```bash
make bats
make test-docker
```

- **Unit Tests (Bats)**: Fast, isolated tests for individual components
  - `test/test_header.bats` - Tests for utility functions
- `test/test_deploy.bats` - Tests for deployment script
- `test/test_syntax.bats` - Syntax validation and linting

- **Integration Tests (Docker)**: Full installation tests in isolated environments
  - `make test-docker` runs the default Ubuntu integration test
  - `make test-docker-all` adds the Arch Linux integration test
  - Docker does not repeat the local Bats suite; use `make test-bats-docker` when needed
  - Tests both remote (curl) and local installation methods
  - Verifies actual system changes
  - macOS test available using `trycua/lumier` VM (experimental)

## References

*   [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles)

*   [takuzoo3868/dotfiles](https://github.com/takuzoo3868/dotfiles)
