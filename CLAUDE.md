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
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup)"
   ```

2. **With package installation:**
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/setup)" -s init
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
- `etc/scripts/deep.d/` - Advanced setup scripts including font installation
- `etc/lib/header.sh` - Shared functions for symlink creation, OS detection, and colored output

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