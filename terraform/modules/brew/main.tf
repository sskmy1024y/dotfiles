resource "terraform_data" "bundle" {
  count = var.enabled ? 1 : 0

  triggers_replace = {
    brewfile_path = var.brewfile_path
    brewfile_hash = fileexists(var.brewfile_path) ? filesha256(var.brewfile_path) : "absent"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      BREWFILE = var.brewfile_path
    }
    command = <<-EOT
      set -euo pipefail
      if ! command -v brew >/dev/null 2>&1; then
        echo "brew is not installed or not on PATH" >&2
        exit 1
      fi

      bundle_log="$(mktemp -t brew-bundle)"
      if brew bundle --verbose --file "$BREWFILE" 2>&1 | tee "$bundle_log"; then
        rm -f "$bundle_log"
      else
        echo "brew bundle failed. Failed dependencies and nearby output:" >&2
        grep -B3 -A3 -E 'has failed|failed to install|failed!' "$bundle_log" >&2 || true
        echo "full brew bundle log: $bundle_log" >&2
        exit 1
      fi
    EOT
  }
}
