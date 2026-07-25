locals {
  directories = {
    for directory in var.directories : directory.path => directory
  }

  touch_files = {
    for file in var.touch_files : file.path => file
  }

  links = {
    for link in var.links : link.target => link
  }
}

resource "terraform_data" "directories" {
  for_each = local.directories

  triggers_replace = {
    path = each.value.path
    mode = each.value.mode
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      DIR  = each.value.path
      MODE = each.value.mode
    }
    command = <<-EOT
      set -euo pipefail
      mkdir -p "$DIR"
      if [ -n "$MODE" ]; then
        chmod "$MODE" "$DIR"
      fi
    EOT
  }
}

resource "terraform_data" "touch_files" {
  for_each = local.touch_files

  triggers_replace = {
    path = each.value.path
    mode = each.value.mode
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      FILE = each.value.path
      MODE = each.value.mode
    }
    command = <<-EOT
      set -euo pipefail
      mkdir -p "$(dirname "$FILE")"
      if [ ! -e "$FILE" ]; then
        touch "$FILE"
      fi
      if [ -n "$MODE" ]; then
        chmod "$MODE" "$FILE"
      fi
    EOT
  }

  depends_on = [terraform_data.directories]
}

resource "terraform_data" "links" {
  for_each = local.links

  input = {
    source = each.value.source
    target = each.value.target
  }

  triggers_replace = {
    source          = each.value.source
    target          = each.value.target
    force           = tostring(each.value.force)
    replace_symlink = tostring(each.value.replace_symlink)
    # Reconcile on every apply so a link skipped because of a conflicting real
    # file, or one removed manually after creation, is (re)created on the next
    # apply. The provisioner below still never overwrites a real (non-symlink)
    # file, so this is safe.
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      SRC             = each.value.source
      DEST            = each.value.target
      FORCE           = tostring(each.value.force)
      REPLACE_SYMLINK = tostring(each.value.replace_symlink)
    }
    command = <<-EOT
      set -euo pipefail
      mkdir -p "$(dirname "$DEST")"

      if [ "$FORCE" = "true" ]; then
        ln -sfn "$SRC" "$DEST"
        exit 0
      fi

      if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
        echo "$DEST already exists; skip symlink"
        exit 0
      fi

      if [ -L "$DEST" ] && [ "$REPLACE_SYMLINK" != "true" ] && [ -e "$DEST" ]; then
        echo "$DEST already exists; skip symlink"
        exit 0
      fi

      ln -sfn "$SRC" "$DEST"
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    environment = {
      SRC  = self.input.source
      DEST = self.input.target
    }
    command = <<-EOT
      set -euo pipefail
      if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC" ]; then
        unlink "$DEST"
      fi
    EOT
  }

  depends_on = [
    terraform_data.directories,
    terraform_data.touch_files
  ]
}
