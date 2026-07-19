variable "directories" {
  description = "Directories to create before linking files."
  type = list(object({
    path = string
    mode = string
  }))
  default = []
}

variable "touch_files" {
  description = "Files to create if they do not already exist."
  type = list(object({
    path = string
    mode = string
  }))
  default = []
}

variable "links" {
  description = "Symlinks to create."
  type = list(object({
    source          = string
    target          = string
    force           = bool
    replace_symlink = bool
  }))
}
