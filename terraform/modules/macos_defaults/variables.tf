variable "enabled" {
  description = "Whether to write macOS defaults."
  type        = bool
  default     = true
}

variable "defaults" {
  description = "macOS defaults entries to write."
  type = map(object({
    domain = string
    key    = string
    type   = string
    value  = string
    global = bool
  }))
}

variable "restart_apps" {
  description = "Apps to restart after defaults are applied."
  type        = list(string)
  default     = []
}
