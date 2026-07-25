variable "enabled" {
  description = "Whether to run brew bundle."
  type        = bool
  default     = true
}

variable "brewfile_path" {
  description = "Absolute path to the Brewfile."
  type        = string
}
