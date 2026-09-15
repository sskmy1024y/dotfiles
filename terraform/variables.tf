variable "enable_brew" {
  description = "Run brew bundle from the repository Brewfile."
  type        = bool
  default     = true
}

variable "enable_macos_defaults" {
  description = "Write macOS defaults via the macos_defaults module."
  type        = bool
  default     = true
}

variable "enable_1password_ssh" {
  description = "Link the 1Password SSH config used on macOS."
  type        = bool
  default     = true
}

variable "enable_linux_ssh_identity" {
  description = "Generate the GitHub SSH identity referenced by git.conf on Linux."
  type        = bool
  default     = false
}

variable "enable_macos_tode" {
  description = "Link tode configuration into its macOS application directories."
  type        = bool
  default     = true
}
