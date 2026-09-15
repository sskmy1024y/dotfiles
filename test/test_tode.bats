#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_dir
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"
}

teardown() {
    teardown_test_dir
}

@test "tode deployment is skipped outside macOS" {
    export DOTFILES_OS_OVERRIDE="ubuntu"
    export DOTFILES_GHOSTTY_INSTALLED=1

    run bash "$DOTPATH/etc/scripts/deploy_tode"

    assert_success
    assert_not_exists "$HOME/.local/share/tode"
    assert_not_exists "$HOME/Library/Application Support/com.mitchellh.ghostty/tode"
    assert_not_exists "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
}

@test "tode deployment preserves directory structure on macOS" {
    export DOTFILES_OS_OVERRIDE="darwin"
    export DOTFILES_GHOSTTY_INSTALLED=0

    run bash "$DOTPATH/etc/scripts/deploy_tode"

    assert_success
    assert_symlink_to \
        "$DOTPATH/config/tode/ghostty/keybinds.ghostty" \
        "$HOME/Library/Application Support/com.mitchellh.ghostty/tode/keybinds.ghostty"
    assert_symlink_to \
        "$DOTPATH/config/tode/local-share/shortcuts.json" \
        "$HOME/.local/share/tode/shortcuts.json"
    assert_symlink_to \
        "$DOTPATH/config/tode/local-share/vscode/user-data/User/settings.json" \
        "$HOME/.local/share/tode/vscode/user-data/User/settings.json"
    assert_symlink_to \
        "$DOTPATH/config/tode/local-share/vscode/user-data/User/keybindings.json" \
        "$HOME/.local/share/tode/vscode/user-data/User/keybindings.json"
}

@test "installed Ghostty gets one tode config-file entry" {
    export DOTFILES_OS_OVERRIDE="darwin"
    export DOTFILES_GHOSTTY_INSTALLED=1
    local config="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    mkdir -p "$(dirname "$config")"
    printf 'font-size = 14' > "$config"

    run bash "$DOTPATH/etc/scripts/deploy_tode"
    assert_success
    run bash "$DOTPATH/etc/scripts/deploy_tode"
    assert_success

    run grep -Fxc 'config-file = ?tode/keybinds.ghostty' "$config"
    assert_success
    assert_output "1"
    run sed -n '1p' "$config"
    assert_output "font-size = 14"
}

@test "tode deployment adopts identical files and preserves different files" {
    export DOTFILES_OS_OVERRIDE="darwin"
    export DOTFILES_GHOSTTY_INSTALLED=0
    local shortcuts="$HOME/.local/share/tode/shortcuts.json"
    local settings="$HOME/.local/share/tode/vscode/user-data/User/settings.json"
    mkdir -p "$(dirname "$shortcuts")" "$(dirname "$settings")"
    cp "$DOTPATH/config/tode/local-share/shortcuts.json" "$shortcuts"
    printf '{"local":true}\n' > "$settings"

    run bash "$DOTPATH/etc/scripts/deploy_tode"

    assert_success
    local deploy_output="$output"
    assert_symlink_to "$DOTPATH/config/tode/local-share/shortcuts.json" "$shortcuts"
    assert_not_link_exists "$settings"
    run cat "$settings"
    assert_output '{"local":true}'
    [[ "$deploy_output" == *"already exists with different contents"* ]]
}

@test "tode cleanup only removes links owned by dotfiles" {
    export DOTFILES_OS_OVERRIDE="darwin"
    export DOTFILES_GHOSTTY_INSTALLED=0

    bash "$DOTPATH/etc/scripts/deploy_tode"
    local managed="$HOME/.local/share/tode/shortcuts.json"
    local unmanaged="$HOME/.local/share/tode/local.txt"
    printf 'keep\n' > "$unmanaged"

    run bash "$DOTPATH/etc/scripts/deploy_tode" --clean

    assert_success
    assert_not_exists "$managed"
    assert_file_exists "$unmanaged"
}

@test "tode cleanup removes the Ghostty config-file entry" {
    export DOTFILES_OS_OVERRIDE="darwin"
    export DOTFILES_GHOSTTY_INSTALLED=1
    local config="$HOME/Library/Application Support/com.mitchellh.ghostty/config"

    bash "$DOTPATH/etc/scripts/deploy_tode"
    run bash "$DOTPATH/etc/scripts/deploy_tode" --clean

    assert_success
    run grep -Fxc 'config-file = ?tode/keybinds.ghostty' "$config"
    assert_failure
    assert_output "0"
}
