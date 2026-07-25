output "keys" {
  description = "Keys for defaults entries managed by this module."
  value       = sort(keys(var.defaults))
}
