#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Runs the test scripts in tests/, or only the ones named on the command line.
# None of the tests need sudo or change anything on the system.
#
# Lint covers install.sh and the scripts changed by the installer hardening
# work, not the whole branch: the rest of Ubuntu-Hyprland 24.04 predates the
# linter and still has findings (mostly SC2034 colour variables in scripts that
# are not touched here). Adding a file to lint_files is a one-line change once
# its findings are fixed.
#
# Usage: ./tests/run-all.sh                 # every tests/*-test.sh
#        ./tests/run-all.sh uninstall       # just tests/uninstall-test.sh
#        ./tests/run-all.sh ppa-series install-issues

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TESTS_DIR")"

shopt -s nullglob
all_tests=("$TESTS_DIR"/*-test.sh)
shopt -u nullglob

if [ "${#all_tests[@]}" -eq 0 ]; then
    echo "no *-test.sh scripts in $TESTS_DIR" >&2
    exit 1
fi

# Accept a full file name, a stem ("ppa-series-test") or the short name
# ("ppa-series") and map it to the script on disk.
resolve() {
    local want cand
    want="$(basename "$1")"
    for cand in "$TESTS_DIR/$want" "$TESTS_DIR/${want%.sh}.sh" "$TESTS_DIR/${want}.sh" "$TESTS_DIR/${want}-test.sh"; do
        if [ -f "$cand" ]; then
            printf '%s' "$cand"
            return 0
        fi
    done
    return 1
}

if [ "$#" -eq 0 ]; then
    scripts=("${all_tests[@]}")
else
    scripts=()
    for name in "$@"; do
        if ! path="$(resolve "$name")"; then
            printf 'no such test: %s (available: %s)\n' \
                "$name" "$(printf '%s ' "${all_tests[@]##*/}" | sed 's/ $//')" >&2
            exit 1
        fi
        scripts+=("$path")
    done
fi

failed=()
for script in "${scripts[@]}"; do
    printf '==> %s\n' "$(basename "$script")"
    if bash "$script"; then
        printf '<== %s ok\n\n' "$(basename "$script")"
    else
        failed+=("$(basename "$script")")
        printf '<== %s FAILED\n\n' "$(basename "$script")"
    fi
done

# ─── lint ───────────────────────────────────────────────────────────────────
# The linter is optional. Any shellcheck finding in this set fails the run.
lint_note="skipped (shellcheck not installed)"
lint_failed=0
if command -v shellcheck >/dev/null 2>&1; then
    shopt -s nullglob
    lint_files=(
        "$REPO_ROOT/install.sh"
        "$REPO_ROOT"/install-scripts/Global_functions.sh
        "$REPO_ROOT"/install-scripts/03-Final-Check.sh
        "$REPO_ROOT"/install-scripts/dotfiles.sh
        "$REPO_ROOT"/install-scripts/hyprland-ppa.sh
        "$REPO_ROOT"/install-scripts/hyprland-ubuntu.sh
        "$TESTS_DIR"/*.sh
    )
    shopt -u nullglob
    printf '==> shellcheck (%d files)\n' "${#lint_files[@]}"
    if lint_out="$(shellcheck -f gcc -S warning "${lint_files[@]}" 2>&1)"; then
        lint_note="clean (${#lint_files[@]} files)"
        printf '<== shellcheck ok (%s)\n\n' "$lint_note"
    else
        printf '%s\n' "$lint_out"
        lint_failed=1
        lint_note="findings"
        printf '<== shellcheck FAILED\n\n'
    fi
fi

if [ "${#failed[@]}" -eq 0 ] && [ "$lint_failed" -eq 0 ]; then
    printf 'all %d test scripts passed; lint: %s\n' "${#scripts[@]}" "$lint_note"
    exit 0
fi
if [ "$lint_failed" -ne 0 ]; then
    printf '%d of %d test scripts failed, shellcheck reported findings\n' "${#failed[@]}" "${#scripts[@]}"
else
    printf '%d of %d test scripts failed: %s\n' "${#failed[@]}" "${#scripts[@]}" "${failed[*]}"
fi
exit 1
