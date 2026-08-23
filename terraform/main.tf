locals {
  dotfiles_root = abspath("${path.root}/..")
  home          = pathexpand("~")

  zsh_links = [
    for file in fileset("${local.dotfiles_root}/config/zsh", "*.zsh") : {
      source          = "${local.dotfiles_root}/config/zsh/${file}"
      target          = "${local.home}/.zsh/${file}"
      force           = false
      replace_symlink = false
    }
  ]

  bin_links = [
    for file in fileset("${local.dotfiles_root}/bin", "*") : {
      source          = "${local.dotfiles_root}/bin/${file}"
      target          = "${local.home}/.local/bin/${file}"
      force           = true
      replace_symlink = true
    }
  ]

  base_links = [
    {
      source          = "${local.dotfiles_root}/etc/scripts/deploy"
      target          = "${local.home}/.local/bin/deploy"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/zsh/.zshrc"
      target          = "${local.home}/.zshrc"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/goenv/.goenvrc"
      target          = "${local.home}/.goenvrc"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/ssh/config"
      target          = "${local.home}/.ssh/config"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/ssh/git.conf"
      target          = "${local.home}/.ssh/git.conf"
      force           = false
      replace_symlink = true
    },
    {
      source          = "${local.dotfiles_root}/config/git/.gitconfig"
      target          = "${local.home}/.gitconfig"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/git/.gitignore.global"
      target          = "${local.home}/.gitignore.global"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/git/.czrc"
      target          = "${local.home}/.czrc"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/tmux/.tmux.conf"
      target          = "${local.home}/.tmux.conf"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/claude/CLAUDE.md"
      target          = "${local.home}/.claude/CLAUDE.md"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/claude/settings.json"
      target          = "${local.home}/.claude/settings.json"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/claude/statusline.sh"
      target          = "${local.home}/.claude/statusline.sh"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/claude/commands"
      target          = "${local.home}/.claude/commands"
      force           = false
      replace_symlink = false
    },
    {
      source          = "${local.dotfiles_root}/config/codex/AGENTS.md"
      target          = "${local.home}/.codex/AGENTS.md"
      force           = false
      replace_symlink = false
    },
  ]

  optional_links = var.enable_1password_ssh ? [
    {
      source          = "${local.dotfiles_root}/config/ssh/1password.conf"
      target          = "${local.home}/.ssh/1password.conf"
      force           = false
      replace_symlink = true
    }
  ] : []

  symlink_directories = [
    {
      path = "${local.home}/.local/bin"
      mode = ""
    },
    {
      path = "${local.home}/.zsh"
      mode = ""
    },
    {
      path = "${local.home}/.ssh"
      mode = "700"
    },
    {
      path = "${local.home}/.git_template/hooks"
      mode = ""
    },
    {
      path = "${local.home}/.claude"
      mode = ""
    },
    {
      path = "${local.home}/.codex"
      mode = ""
    }
  ]

  touch_files = [
    {
      path = "${local.home}/.ssh/authorized_keys"
      mode = "600"
    }
  ]

  defaults = {
    initial_key_repeat = {
      domain = ""
      key    = "InitialKeyRepeat"
      type   = "-int"
      value  = "10"
      global = true
    }
    key_repeat = {
      domain = ""
      key    = "KeyRepeat"
      type   = "-int"
      value  = "2"
      global = true
    }
    press_and_hold = {
      domain = ""
      key    = "ApplePressAndHoldEnabled"
      type   = "-bool"
      value  = "false"
      global = true
    }
    dock_tilesize = {
      domain = "com.apple.dock"
      key    = "tilesize"
      type   = "-integer"
      value  = "46"
      global = false
    }
    dock_size_immutable = {
      domain = "com.apple.dock"
      key    = "size-immutable"
      type   = "-boolean"
      value  = "true"
      global = false
    }
    no_network_ds_store = {
      domain = "com.apple.desktopservices"
      key    = "DSDontWriteNetworkStores"
      type   = "-bool"
      value  = "true"
      global = false
    }
    quit_printer_when_finished = {
      domain = "com.apple.print.PrintingPrefs"
      key    = "Quit When Finished"
      type   = "-bool"
      value  = "true"
      global = false
    }
    expose_animation_duration = {
      domain = "com.apple.dock"
      key    = "expose-animation-duration"
      type   = "-float"
      value  = "0.15"
      global = false
    }
    quicklook_keep_playing = {
      domain = "com.apple.finder"
      key    = "AutoStopWhenSelectionChanges"
      type   = "-bool"
      value  = "false"
      global = false
    }
  }
}

resource "terraform_data" "linux_ssh_identity" {
  count = var.enable_linux_ssh_identity ? 1 : 0

  triggers_replace = {
    private_key = "${local.home}/.ssh/github-key"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      PRIVATE_KEY = "${local.home}/.ssh/github-key"
    }
    command = <<-EOT
      set -euo pipefail
      mkdir -p "$(dirname "$PRIVATE_KEY")"
      chmod 700 "$(dirname "$PRIVATE_KEY")"
      if [ ! -f "$PRIVATE_KEY" ]; then
        ssh-keygen -q -t ed25519 -f "$PRIVATE_KEY" -N ""
      fi
      chmod 600 "$PRIVATE_KEY"
      chmod 644 "$PRIVATE_KEY.pub"
    EOT
  }
}

resource "terraform_data" "tpm" {
  triggers_replace = {
    installer_sha256 = filesha256("${local.dotfiles_root}/etc/scripts/install.d/30_tmux.sh")
    install_path     = "${local.home}/.tmux/plugins/tpm"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      DOTPATH = local.dotfiles_root
    }
    command = "bash \"$DOTPATH/etc/scripts/install.d/30_tmux.sh\""
  }
}

module "symlinks" {
  source = "./modules/symlink"

  directories = local.symlink_directories
  touch_files = local.touch_files
  links       = concat(local.base_links, local.optional_links, local.zsh_links, local.bin_links)

  depends_on = [
    terraform_data.linux_ssh_identity,
    terraform_data.tpm
  ]
}

module "brew" {
  source = "./modules/brew"

  enabled       = var.enable_brew
  brewfile_path = "${local.dotfiles_root}/etc/scripts/install.d/Brewfile"

  depends_on = [module.symlinks]
}

module "macos_defaults" {
  source = "./modules/macos_defaults"

  enabled      = var.enable_macos_defaults
  defaults     = local.defaults
  restart_apps = ["Dock", "Finder"]

  depends_on = [module.brew]
}
