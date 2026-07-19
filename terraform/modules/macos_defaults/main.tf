resource "terraform_data" "defaults" {
  for_each = var.enabled ? var.defaults : {}

  triggers_replace = {
    spec = jsonencode(each.value)
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      DOMAIN = each.value.domain
      KEY    = each.value.key
      TYPE   = each.value.type
      VALUE  = each.value.value
      GLOBAL = tostring(each.value.global)
    }
    command = <<-EOT
      set -euo pipefail
      if [ "$GLOBAL" = "true" ]; then
        defaults write -g "$KEY" "$TYPE" "$VALUE"
      else
        defaults write "$DOMAIN" "$KEY" "$TYPE" "$VALUE"
      fi
    EOT
  }
}

resource "terraform_data" "restart_apps" {
  count = var.enabled && length(var.restart_apps) > 0 ? 1 : 0

  triggers_replace = {
    defaults     = sha256(jsonencode(var.defaults))
    restart_apps = join(",", var.restart_apps)
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = join("\n", [for app in var.restart_apps : "killall ${app} >/dev/null 2>&1 || true"])
  }

  depends_on = [terraform_data.defaults]
}
