output "targets" {
  description = "Symlink targets in the home directory."
  value       = sort(keys(local.links))
}
