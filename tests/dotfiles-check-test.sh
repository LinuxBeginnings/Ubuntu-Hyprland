#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# dotfiles.sh used to end on a printf, so it exited 0 even when copy.sh failed
# or wrote nothing and install.sh reported the dots as installed. This checks
# install_dots with a fake copy.sh; it needs no network and no sudo.
#
# Usage: ./tests/dotfiles-check-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTS="$ROOT/install-scripts/dotfiles.sh"

[ -f "$DOTS" ] || {
    echo "cannot find install-scripts/dotfiles.sh" >&2
    exit 1
}

WORK="$(mktemp -d)" || {
    echo "cannot create a temp directory" >&2
    exit 1
}
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n         %s\n' "$1" "${2:-}"; }

check_eq() {
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1" "expected [$3], got [$2]"
    fi
}

check_contains() {
    case "$2" in
    *"$3"*) pass "$1" ;;
    *) fail "$1" "'$3' not in: $(printf '%s' "$2" | head -3 | tr '\n' ' ')" ;;
    esac
}

FUNCS="$WORK/funcs.sh"
body="$(awk '
    index($0, "install_dots() {") == 1 { on = 1 }
    on { print }
    on && /^\}$/ { exit }
' "$DOTS")"
if [ -z "$body" ]; then
    echo "could not extract install_dots from install-scripts/dotfiles.sh" >&2
    exit 1
fi
{
    printf '%s\n' 'ERROR="[ERROR]"'
    printf '%s\n' "$body"
} >"$FUNCS"

OUT=""
RC=0
run_dots() { # run_dots <checkout dir> <home>
    OUT="$(cd "$1" && HOME="$2" bash -c 'source "$0"; install_dots' "$FUNCS" 2>&1)"
    RC=$?
}

new_case() { # new_case <name> ; sets CASE and HOME_DIR
    CASE="$WORK/$1"
    HOME_DIR="$WORK/home-$1"
    mkdir -p "$CASE" "$HOME_DIR"
}

echo
echo "a working copy is reported as success"
new_case good
printf '#!/usr/bin/env bash\nmkdir -p "$HOME/.config/hypr"\n' >"$CASE/copy.sh"
chmod 644 "$CASE/copy.sh"
run_dots "$CASE" "$HOME_DIR"
check_eq "exit status" "$RC" "0"
check_eq "the copy ran" "$([ -d "$HOME_DIR/.config/hypr" ] && echo yes)" "yes"

echo
echo "a copy that writes nothing is a failure"
new_case silent
printf '#!/usr/bin/env bash\nexit 0\n' >"$CASE/copy.sh"
chmod 644 "$CASE/copy.sh"
run_dots "$CASE" "$HOME_DIR"
check_eq "exit status" "$RC" "1"
check_contains "the missing config is named" "$OUT" ".config/hypr is missing"

echo
echo "a failing copy is a failure"
new_case broken
printf '#!/usr/bin/env bash\nexit 7\n' >"$CASE/copy.sh"
chmod 644 "$CASE/copy.sh"
run_dots "$CASE" "$HOME_DIR"
check_eq "exit status" "$RC" "1"
check_contains "copy.sh is named" "$OUT" "copy.sh failed"

echo
echo "a missing copy.sh is a failure"
new_case missing
run_dots "$CASE" "$HOME_DIR"
check_eq "exit status" "$RC" "1"
check_contains "the chmod failure is named" "$OUT" "Could not make copy.sh executable"

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
