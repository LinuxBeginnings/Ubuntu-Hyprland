#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Before the screen is cleared, install.sh lists what did not install and offers
# retry / continue / abort. These tests drive that prompt with stubbed scripts:
# nothing is installed and no sudo or terminal is needed.
#
# Usage: ./tests/install-issues-test.sh

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
    *) fail "$1" "'$3' not in: $(printf '%s' "$2" | head -4 | tr '\n' ' ')" ;;
    esac
}

check_lacks() {
    case "$2" in
    *"$3"*) fail "$1" "'$3' unexpectedly present" ;;
    *) pass "$1" ;;
    esac
}

# ─── extract the helpers from install.sh ───────────────────────────────────
FUNCS="$WORK/funcs.sh"
: >"$FUNCS"
for fn in record_optional_failure clear_optional_failure run_optional \
    collect_install_issues print_install_issues resolve_install_issues; do
    body="$(awk -v fn="$fn" '
        !on && index($0, fn "() {") == 1 { on = 1 }
        on { print }
        on && /^\}/ { exit }
    ' "$INSTALL")"
    if [ -z "$body" ]; then
        echo "could not extract $fn from install.sh" >&2
        exit 1
    fi
    printf '%s\n' "$body" >>"$FUNCS"
done
export WORK FUNCS

RUN="$WORK/run.sh"
{
    printf '%s\n' 'WARN="[WARN]" ERROR="[ERROR]" NOTE="[NOTE]" OK="[OK]" INFO="[INFO]" CAT="[ACTION]"'
    printf '%s\n' 'LOG="$WORK/install.log"'
    printf '%s\n' 'REPO_ROOT="$WORK/repo"'
    printf '%s\n' 'optional_failures_file="$REPO_ROOT/Install-Logs/optional-failures.txt"'
    printf '%s\n' 'failed_optional=()'
    printf '%s\n' '. "$FUNCS"'
    # Stub: "fail-*" scripts fail until the retry flag exists; others succeed.
    printf '%s\n' 'execute_script() {'
    printf '%s\n' '    [ -f "$WORK/now-good" ] && return 0'
    printf '%s\n' '    case "$1" in fail*) return 1 ;; *) return 0 ;; esac'
    printf '%s\n' '}'
    # "with-failure" arrives the way a real failure does: the component is in the
    # in-memory list and in the record file before the summary runs.
    printf '%s\n' 'if [ "${1:-}" = "with-failure" ]; then'
    printf '%s\n' '    failed_optional=("fail-yazi.sh")'
    printf '%s\n' '    record_optional_failure fail-yazi.sh'
    printf '%s\n' 'fi'
    printf '%s\n' 'resolve_install_issues'
    printf '%s\n' 'printf "rc=%s\n" "$?"'
} >"$RUN"

FAIL_FILE="$WORK/repo/Install-Logs/optional-failures.txt"
PKG_FILE="$WORK/repo/Install-Logs/failed-packages.txt"

reset_repo() {
    mkdir -p "$WORK/repo/Install-Logs"
    : >"$FAIL_FILE"
    : >"$PKG_FILE"
    rm -f "$WORK/now-good"
}

echo
echo "a clean run says nothing and continues"
reset_repo
OUT="$(printf 'c\n' | bash "$RUN" 2>&1)"
check_lacks "no failure header" "$OUT" "did not complete"
check_contains "the run continues" "$OUT" "rc=0"

echo
echo "failures are listed with their source"
reset_repo
printf 'somepkg\n' >"$PKG_FILE"
OUT="$(printf 'c\n' | bash "$RUN" with-failure 2>&1)"
check_contains "the header names the problem" "$OUT" "Some parts of the install did not complete:"
check_contains "the component is listed" "$OUT" "  - fail-yazi.sh"
check_contains "the package is listed" "$OUT" "  - package: somepkg"

echo
echo "a non-interactive run does not wait for an answer"
reset_repo
OUT="$(bash "$RUN" with-failure </dev/null 2>&1)"
check_contains "it says so" "$OUT" "Not running interactively; continuing to the final check."
check_contains "it continues" "$OUT" "rc=0"

echo
echo "continue keeps the run going"
reset_repo
OUT="$(printf 'c\n' | ISSUES_ASSUME_TTY=1 bash "$RUN" with-failure 2>&1)"
check_contains "it confirms" "$OUT" "Continuing with the parts that did install."
check_contains "it continues" "$OUT" "rc=0"

echo
echo "abort stops before the final check"
reset_repo
OUT="$(printf 'a\n' | ISSUES_ASSUME_TTY=1 bash "$RUN" with-failure 2>&1)"
RC=$?
check_contains "it explains the abort" "$OUT" "Aborted at your request. Re-run ./install.sh to finish."
check_eq "the exit is non-zero" "$RC" "1"

echo
echo "an unknown answer is asked again"
reset_repo
OUT="$(printf 'x\na\n' | ISSUES_ASSUME_TTY=1 bash "$RUN" with-failure 2>&1)"
RC=$?
check_contains "the prompt repeats" "$OUT" "Please answer r, c or a."
check_eq "then abort works" "$RC" "1"

echo
echo "retry re-runs the component and clears the record"
reset_repo
touch "$WORK/now-good"
OUT="$(printf 'r\n' | ISSUES_ASSUME_TTY=1 bash "$RUN" with-failure 2>&1)"
check_contains "the retry is reported" "$OUT" "Retried component(s) installed."
check_eq "the record is empty" "$(cat "$FAIL_FILE")" ""
check_contains "the run continues" "$OUT" "rc=0"

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
