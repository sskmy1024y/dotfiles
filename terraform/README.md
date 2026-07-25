# Terraform dotfiles

This directory is an experimental Terraform entrypoint for managing this
dotfiles repository alongside the existing shell scripts.

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

The remote installer wraps that flow:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sskmy1024y/dotfiles/master/etc/bootstrap)"
```

To apply only one part:

```sh
terraform apply -target=module.symlinks
terraform apply -target=module.brew
terraform apply -target=module.macos_defaults
```

## Variables

- `enable_brew`: run `brew bundle` from `etc/scripts/install.d/Brewfile`.
- `enable_macos_defaults`: write macOS defaults.
- `enable_1password_ssh`: link the 1Password SSH config.

All are enabled by default because this Terraform entrypoint currently targets
the macOS workflow. Disable them explicitly when testing on non-macOS hosts.

## Scope

This intentionally does not replace every shell side effect yet. TPM cloning,
SSH key generation on Linux, Touch ID sudo configuration, Cica font downloads,
and Gatekeeper changes remain in the shell scripts because they either require
network access, sudo, or host-specific branching.
