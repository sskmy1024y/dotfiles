# Terraform dotfiles

This directory is the declarative implementation used by `dotfiles install`
and `dotfiles sync`.

It follows the same broad flow as the shell implementation:

1. `module.symlinks` links repository config into `$HOME`.
2. `module.brew` runs `brew bundle` when the Brewfile changes.
3. `module.macos_defaults` writes macOS defaults and restarts affected apps.

## Usage

```sh
cd terraform
terraform init
terraform plan
terraform apply
```

The CLI and remote installer wrap that flow:

```sh
curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/install.sh | sh
dotfiles plan
```

To apply only one part:

```sh
terraform apply -target=module.symlinks
terraform apply -target=module.brew
terraform apply -target=module.macos_defaults
```

## Variables

- `enable_brew`: run `brew bundle` from `config/homebrew/Brewfile`.
- `enable_macos_defaults`: write macOS defaults.
- `enable_1password_ssh`: link the 1Password SSH config.
- `enable_macos_tode`: link the Tode and Ghostty integration on macOS.

The CLI disables macOS-only variables on other platforms.

## Scope

Terraform owns directories, symlinks, the Linux SSH identity, Homebrew bundle,
macOS defaults, and Tode integration. Runtime installers and explicitly
optional extras remain small shell components under `etc/scripts/`.
