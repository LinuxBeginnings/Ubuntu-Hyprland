#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks the wiring of install.sh's PPA path: it falls back to the Ubuntu
# repository script when the PPA script fails, does not fall back when it
# succeeds, and fails the install when both paths fail.
#
# The `ppa)` branch of install.sh is extracted and run against a stubbed
# execute_script, so nothing is installed and no sudo is needed. A real
# end-to-end install still has to be run on a machine, but this pins the
# control flow.
#
# Usage: ./tests/install-fallback-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$ROOT/install.sh"

[ -f "$INSTALL" ] || {
    echo "cannot find install.sh" >&2
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

check_lacks() {
    case "$2" in
    *"$3"*) fail "$1" "'$3' unexpectedly present" ;;
    *) pass "$1" ;;
    esac
}

# ─── harness: the ppa branch, with execute_script stubbed ───────────────────
BRANCH="$WORK/branch.sh"
{
    printf '%s\n' '#!/usr/bin/env bash' 'set -uo pipefail'
    printf '%s\n' 'INFO="[INFO]"; WARN="[WARN]"; ERROR="[ERROR]"; SKY_BLUE=""; RESET=""'
    printf 'LOG=%q\n' "$WORK/install.log"
    cat <<'STUB'
execute_script() {
    printf '%s\n' "$1" >>"$CALLS"
    if [ -f "$STUB_DIR/$1.status" ]; then
        return "$(cat "$STUB_DIR/$1.status")"
    fi
    return 0
}
case ppa in
ppa)
STUB
    sed -n '/^ppa)$/,/^    ;;$/p' "$INSTALL" | sed '1d;$d'
    printf '%s\n' ';;' 'esac'
} >"$BRANCH"

bash -n "$BRANCH" || {
    echo "could not extract a runnable ppa branch from install.sh" >&2
    exit 1
}

run_branch() { # run_branch <case> <ppa status> <ubuntu status>
    local case_dir="$WORK/$1"
    mkdir -p "$case_dir/stub"
    printf '%s' "$2" >"$case_dir/stub/hyprland-ppa.sh.status"
    [ "$3" = "-" ] || printf '%s' "$3" >"$case_dir/stub/hyprland-ubuntu.sh.status"
    STUB_DIR="$case_dir/stub" CALLS="$case_dir/calls" bash "$BRANCH" >"$case_dir/output" 2>&1
}

calls() { cat "$WORK/$1/calls" 2>/dev/null | tr '\n' ' ' | sed 's/ $//'; }
output() { cat "$WORK/$1/output" 2>/dev/null; }

echo
echo "PPA fails, Ubuntu repositories succeed"
run_branch fallback 1 0
check_eq "exits 0" "$?" "0"
check_eq "runs the Ubuntu script after the PPA" "$(calls fallback)" "hyprland-ppa.sh hyprland-ubuntu.sh"
check_contains "announces the fallback" "$(output fallback)" "falling back to the"
check_contains "names the Ubuntu repositories" "$(output fallback)" "Ubuntu repositories"

echo
echo "PPA succeeds"
run_branch ppa-ok 0 -
check_eq "exits 0" "$?" "0"
check_eq "does not run the Ubuntu script" "$(calls ppa-ok)" "hyprland-ppa.sh"
check_lacks "no fallback message" "$(output ppa-ok)" "falling back to the"

echo
echo "both paths fail"
run_branch both-fail 1 1
check_eq "exits 1" "$?" "1"
check_eq "tries both scripts" "$(calls both-fail)" "hyprland-ppa.sh hyprland-ubuntu.sh"
check_contains "reports the combined failure" "$(output both-fail)" "could not be installed from the PPA or the Ubuntu repositories"

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
