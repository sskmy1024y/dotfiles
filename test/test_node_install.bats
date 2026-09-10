#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_dir
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME/.anyenv/envs/nodenv/plugins/node-build/.git"
    mkdir -p "$HOME/.anyenv/envs/nodenv/plugins/nodenv-package-json-engine/.git"
    mkdir -p "$TEST_TEMP_DIR/bin"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

teardown() {
    teardown_test_dir
}

@test "Node runtime installer updates node-build and installs the latest stable Node" {
    cat > "$TEST_TEMP_DIR/bin/nodenv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  root)
    printf "%s\n" "$HOME/.anyenv/envs/nodenv"
    ;;
  install)
    if [ "${2:-}" = "--list" ]; then
      if [ -f "$HOME/.node-build-updated" ]; then
        printf "%s\n" "22.22.2" "24.16.0" "25.9.0" "graal+ce-19.2.1"
      else
        printf "%s\n" "22.22.2" "24.15.0" "graal+ce-19.2.1"
      fi
    else
      printf "install %s\n" "$2" >> "$HOME/nodenv-calls"
    fi
    ;;
  global)
    printf "global %s\n" "$2" >> "$HOME/nodenv-calls"
    ;;
  *)
    exit 1
    ;;
esac
EOF
    chmod +x "$TEST_TEMP_DIR/bin/nodenv"

    cat > "$TEST_TEMP_DIR/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "$1" = "-C" ] && [ "$3" = "pull" ] && [ "$4" = "--ff-only" ]; then
  printf "%s\n" "updated" > "$HOME/.node-build-updated"
  exit 0
fi

exit 1
EOF
    chmod +x "$TEST_TEMP_DIR/bin/git"

    run bash "$DOTPATH/etc/scripts/runtimes/node.sh"

    assert_success
    assert_output --partial "Updating node-build definitions..."
    assert_file_contains "$HOME/nodenv-calls" "install 25.9.0"
    assert_file_contains "$HOME/nodenv-calls" "global 25.9.0"
}
