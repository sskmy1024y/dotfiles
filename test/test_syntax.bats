#!/usr/bin/env bats

# Repository-wide shell smoke checks.

load test_helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

shell_scripts() {
    find "$DOTPATH" -type f \
        \( -name '*.sh' -o -perm -u+x \) \
        -not -path "$DOTPATH/.git/*" \
        -not -path "$DOTPATH/test/bats/*" \
        -print0
}

@test "shell scripts parse with their declared shell" {
    local script failed=0

    while IFS= read -r -d '' script; do
        case "$(head -n 1 "$script")" in
            '#!/bin/sh' | '#!/usr/bin/env sh')
                sh -n "$script" || failed=$((failed + 1))
                ;;
            *bash*)
                bash -n "$script" || failed=$((failed + 1))
                ;;
        esac
    done < <(shell_scripts)

    [ "$failed" -eq 0 ]
}

@test "shell scripts pass ShellCheck when available" {
    skip_if_missing shellcheck
    local script failed=0

    while IFS= read -r -d '' script; do
        case "$(head -n 1 "$script")" in
            *bash* | '#!/bin/sh' | '#!/usr/bin/env sh')
                shellcheck -e SC1090,SC1091,SC2034,SC2155 "$script" || failed=$((failed + 1))
                ;;
        esac
    done < <(shell_scripts)

    [ "$failed" -eq 0 ]
}

@test "public command help is available" {
    run bash "$DOTPATH/bin/dotfiles" help
    assert_success
    assert_output --partial "Usage: dotfiles"

    run bash "$DOTPATH/etc/install" --help
    assert_success
    assert_output --partial "Usage: install"
}

@test "public entrypoints are executable" {
    local script
    for script in \
        "$DOTPATH/install.sh" \
        "$DOTPATH/bin/dotfiles" \
        "$DOTPATH/etc/bootstrap" \
        "$DOTPATH/etc/install" \
        "$DOTPATH/etc/scripts/deploy" \
        "$DOTPATH/etc/scripts/init"; do
        [ -x "$script" ]
    done
}
