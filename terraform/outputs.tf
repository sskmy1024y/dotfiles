output "symlink_targets" {
  description = "Home paths managed by the symlink module."
  value       = module.symlinks.targets
}

output "brewfile_path" {
  description = "Brewfile used by the brew module."
  value       = module.brew.brewfile_path
}

output "macos_defaults_keys" {
  description = "macOS defaults entries managed by Terraform."
  value       = module.macos_defaults.keys
}
