#!/usr/bin/env bats

load test_helper

setup() {
    setup_test_dir
    export HOME="$TEST_TEMP_DIR/home"
    export DOTFILES_T3CODE_SKIP_INSTALL=1
    mkdir -p "$HOME"
    unset T3CODE_HOME
}

teardown() {
    teardown_test_dir
}

@test "t3code deployment is skipped on macOS" {
    export DOTFILES_OS_OVERRIDE="darwin"

    run bash "$DOTPATH/etc/scripts/deploy_t3code"

    assert_success
    assert_not_exists "$HOME/.t3"
}

@test "t3code settings are seeded when missing" {
    export DOTFILES_OS_OVERRIDE="linux"

    run bash "$DOTPATH/etc/scripts/deploy_t3code"

    assert_success
    run cmp "$DOTPATH/config/t3code/settings.json" "$HOME/.t3/userdata/settings.json"
    assert_success
}

@test "t3code settings merge keeps unmanaged keys and overrides managed ones" {
    export DOTFILES_OS_OVERRIDE="linux"
    mkdir -p "$HOME/.t3/userdata"
    printf '{"localOnly":1,"defaultAutoPull":false}' > "$HOME/.t3/userdata/settings.json"

    run bash "$DOTPATH/etc/scripts/deploy_t3code"
    assert_success

    [ "$(jq -c '[.localOnly, .defaultAutoPull]' "$HOME/.t3/userdata/settings.json")" = "[1,true]" ]
}
