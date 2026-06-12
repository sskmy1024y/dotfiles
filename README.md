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

## 📂 Directory structure

```sh
dotfiles/
 ├── bin/            # Useful command line scripts
 ├── config/         # Dotfiles
 │   ├── claude      # Claude AI configuration
 │   ├── git         # Git configuration
 │   ├── iterm       # iTerm2 configuration
 │   ├── ssh         # SSH configuration
 │   ├── tmux        # Tmux configuration
 │   └── zsh         # Zsh shell configuration
 ├── doc/            # Document files
 ├── etc/
 │   ├── lib         # Library scripts
 │   └── scripts     # Setup & Install scripts
 │       ├── deep.d  # Advanced setup scripts
 │       └── install.d # Package installation scripts
 ├── test/           # Test suite
 │   ├── bats        # Bats testing framework
 │   ├── docker      # Docker test environments
 │   └── *.bats      # Test files
 └── Makefile
```

## 📦 Setup

Just copy and execute this !!!

```bash
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap)"
```

If you want to install a [dev-packages](https://github.com/takuzoo3868/dotfiles/tree/master/etc/scripts/install.d), add `init` as an optional argument.

```bash
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap)" -s init
```

### Setup using Makefile

```bash
$ git clone https://github.com/sskmy1024y/dotfiles.git $HOME/.dotfiles
$ cd $HOME/.dotfiles
$ make install
```

Incidentally, `make install` will perform the following tasks.

*   `make deploy` Deploying dotfiles to home directory (creating symlinks)
*   `make init` Installing packages and setting up environment

### Available Commands

```bash
$ make help  # Show all available commands
```

| Command | Description |
|---------|-------------|
| `make install` | Run make deploy, init |
| `make deploy` | Create symlink to home directory |
| `make init` | Setup environment settings |
| `make update` | Fetch changes for this repo |
| `make deep` | Setup more finicky settings (fonts, advanced tools) |
| `make clean` | Remove dotfiles and this repo |
| `make check` | Check if it is ready to install |

## 💁‍♀️ Recommend

I recommend installing [Nerd fonts](https://github.com/ryanoasis/nerd-fonts) to display graphical icons on terminal. 

A script to automate the installation is placed in `etc/init/deep.d/98_font.sh`.

```bash
$ make deep
```

## 🧪 Testing

The dotfiles include comprehensive automated tests using Bats (Bash Automated Testing System) and Docker.

### Running Tests

```bash
# Run local unit tests
$ make test

# Run all Docker-based integration tests
$ make test-docker

# Run Docker tests for specific OS
$ make test-docker-ubuntu
$ make test-docker-archlinux

# Run Bats tests in Docker
$ make test-bats                # Both Ubuntu and Arch Linux
$ make test-bats-ubuntu          # Ubuntu only
$ make test-bats-archlinux       # Arch Linux only
$ make test-bats-ci              # CI mode (both OS)

# Run macOS Docker test (requires Docker Desktop on macOS)
$ make test-mac-local            # Run tests in macOS VM container

# Rebuild Docker images and run tests
$ make test-rebuild
```

### Test Structure

- **Unit Tests (Bats)**: Fast, isolated tests for individual components
  - `test/test_header.bats` - Tests for utility functions
  - `test/test_symlink.bats` - Tests for symlink operations
  - `test/test_deploy.bats` - Tests for deployment script
  - `test/test_syntax.bats` - Syntax validation and linting

- **Integration Tests (Docker)**: Full installation tests in isolated environments
  - Tests both Ubuntu and Arch Linux
  - Tests both remote (curl) and local installation methods
  - Verifies actual system changes
  - macOS test available using `trycua/lumier` VM (experimental)

### Environment Variables

- `CI` or `DOTFILES_TEST` - When set, SSH keys will be generated without passphrase prompts
- `SKIP_BATS_TESTS` - Skip running Bats tests (useful when test directory is not available)

For manual installations, you can set these variables to avoid interactive prompts:

```bash
$ DOTFILES_TEST=1 make deploy
```

## References

*   [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles)

*   [takuzoo3868/dotfiles](https://github.com/takuzoo3868/dotfiles)
