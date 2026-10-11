#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_dir
    export HOME="$TEST_TEMP_DIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$HOME" "$TEST_TEMP_DIR/bin"
    # Keep only the system tools so a host-installed mise or brew is not used.
    export PATH="$TEST_TEMP_DIR/bin:/usr/bin:/bin"
}

teardown() {
    teardown_test_dir
}

write_fake_mise() {
    local dest="$1"
    mkdir -p "$(dirname "$dest")"
    cat > "$dest" <<'EOF'
#!/usr/bin/env bash
printf "%s|%s|%s\n" "$*" "$PWD" "${MISE_GLOBAL_CONFIG_FILE:-}" >> "$HOME/mise-calls"
EOF
    chmod +x "$dest"
}

@test "mise installer runs mise install from HOME with an existing mise" {
    write_fake_mise "$TEST_TEMP_DIR/bin/mise"
    mkdir -p "$XDG_CONFIG_HOME/mise"
    ln -s "$DOTPATH/config/mise/config.toml" "$XDG_CONFIG_HOME/mise/config.toml"

    run bash "$DOTPATH/etc/scripts/runtimes/mise.sh"

    assert_success
    assert_output --partial "mise is already installed"
    assert_file_contains "$HOME/mise-calls" "install --yes|$HOME|$"
}

@test "mise installer falls back to the repository config before sync" {
    write_fake_mise "$TEST_TEMP_DIR/bin/mise"

    run bash "$DOTPATH/etc/scripts/runtimes/mise.sh"

    assert_success
    assert_file_contains "$HOME/mise-calls" "install --yes|$HOME|$DOTPATH/config/mise/config.toml"
}

@test "mise installer uses the standalone installer into ~/.local/bin" {
    skip_if_os darwin
    cat > "$TEST_TEMP_DIR/bin/curl" <<EOF
#!/usr/bin/env bash
cat <<'SCRIPT'
#!/bin/sh
mkdir -p "\$(dirname "\$MISE_INSTALL_PATH")"
cat > "\$MISE_INSTALL_PATH" <<'MISE'
#!/usr/bin/env bash
printf "%s\n" "\$*" >> "\$HOME/mise-calls"
MISE
chmod +x "\$MISE_INSTALL_PATH"
SCRIPT
EOF
    chmod +x "$TEST_TEMP_DIR/bin/curl"

    run bash "$DOTPATH/etc/scripts/runtimes/mise.sh"

    assert_success
    assert_file_executable "$HOME/.local/bin/mise"
    assert_file_contains "$HOME/mise-calls" "install --yes"
}

@test "global mise config opts in to idiomatic version files" {
    assert_file_contains "$DOTPATH/config/mise/config.toml" 'idiomatic_version_file_enable_tools = \[.*"node".*\]'
    assert_file_contains "$DOTPATH/config/mise/config.toml" 'idiomatic_version_file_enable_tools = \[.*"python".*\]'
    assert_file_contains "$DOTPATH/config/mise/config.toml" 'idiomatic_version_file_enable_tools = \[.*"pnpm".*\]'
}
