#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Optional components warn and continue, but their failures have to survive the
# screen clear: run_optional records them in Install-Logs/optional-failures.txt
# and 03-Final-Check.sh prints that file. The final check must not write those
# names into its package log, because update-deps.sh reads it as a package list.
#
# Usage: ./tests/optional-summary-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$ROOT/install.sh"
FINAL="$ROOT/install-scripts/03-Final-Check.sh"

for f in "$INSTALL" "$FINAL"; do
    [ -f "$f" ] || {
        echo "cannot find $f" >&2
        exit 1
    }
done

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

# ─── extract the recording helpers from install.sh ─────────────────────────
FUNCS="$WORK/funcs.sh"
: >"$FUNCS"
printf '%s\n' "optional_failures_file=\"\$WORK/repo/Install-Logs/optional-failures.txt\"" >>"$FUNCS"
for fn in record_optional_failure clear_optional_failure run_optional; do
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

# ─── extract the summary block from 03-Final-Check.sh ──────────────────────
SUMMARY="$WORK/summary.sh"
awk '
    /^# Optional components that did not install/ { on = 1 }
    on && /^# Log missing packages/ { exit }
    on { print }
' "$FINAL" >"$SUMMARY"
[ -s "$SUMMARY" ] || {
    echo "could not extract the optional summary from 03-Final-Check.sh" >&2
    exit 1
}
export WORK FUNCS SUMMARY

# ─── harness: run_optional with a stubbed execute_script ───────────────────
RUN="$WORK/run.sh"
{
    printf '%s\n' 'WARN="[WARN]" LOG="$WORK/install.log"'
    printf '%s\n' 'execute_script() {'
    printf '%s\n' '    [ -f "$WORK/now-good" ] && return 0'
    printf '%s\n' '    case "$1" in fail*) return 1 ;; *) return 0 ;; esac'
    printf '%s\n' '}'
    printf '%s\n' '. "$FUNCS"'
    printf '%s\n' 'run_optional "$1"'
    printf '%s\n' 'printf "rc=%s\n" "$?"'
} >"$RUN"

run_optional_check() { # run_optional_check <script>
    bash "$RUN" "$1" 2>&1
}

FAIL_FILE="$WORK/repo/Install-Logs/optional-failures.txt"

echo
echo "a failing optional component warns but does not stop the install"
OUT="$(run_optional_check fail-yazi.sh)"
check_contains "the failure is a warning" "$OUT" "fail-yazi.sh failed; continuing"
check_contains "the run continues" "$OUT" "rc=0"
check_eq "the component is recorded" "$(cat "$FAIL_FILE")" "fail-yazi.sh"

echo
echo "a second failure is added"
run_optional_check fail-dots.sh >/dev/null
check_eq "both components are recorded" "$(cat "$FAIL_FILE")" "fail-yazi.sh
fail-dots.sh"

echo
echo "a successful component is not recorded"
OUT="$(run_optional_check wallust.sh)"
check_lacks "no warning" "$OUT" "failed; continuing"
check_eq "the record is unchanged" "$(wc -l <"$FAIL_FILE" | tr -d ' ')" "2"

echo
echo "a retry that works clears the recorded failure"
touch "$WORK/now-good"
OUT="$(run_optional_check fail-yazi.sh)"
check_lacks "no warning on success" "$OUT" "failed; continuing"
check_eq "the stale entry is gone" "$(cat "$FAIL_FILE")" "fail-dots.sh"

echo
echo "the final check prints the recorded components"
RUN_SUMMARY="$WORK/summary.sh.run"
{
    printf '%s\n' 'REPO_ROOT="$WORK/repo"'
    printf '%s\n' 'WARN="[WARN]"'
    printf '%s\n' 'LOG="$WORK/check.log"'
    printf '%s\n' ': > "$LOG"'
    printf '%s\n' '. "$SUMMARY"'
} >"$RUN_SUMMARY"

OUT="$(bash "$RUN_SUMMARY" 2>&1)"
check_contains "the section is named" "$OUT" "These optional components did not install:"
check_contains "the component is listed" "$OUT" "  - fail-dots.sh"

printf '\n\n\n' >"$FAIL_FILE"
OUT="$(bash "$RUN_SUMMARY" 2>&1)"
check_eq "blank entries print nothing" "$OUT" "[WARN] These optional components did not install:"

printf 'yazi.sh\ndotfiles.sh\n' >"$FAIL_FILE"
OUT="$(bash "$RUN_SUMMARY" 2>&1)"
check_contains "several components are listed" "$OUT" "  - yazi.sh"
check_contains "the second one too" "$OUT" "  - dotfiles.sh"

echo
echo "the package log is left alone"
check_eq "the final check log stays empty" "$(wc -c <"$WORK/check.log" 2>/dev/null | tr -d ' ')" "0"

echo
echo "an empty record prints nothing"
: >"$FAIL_FILE"
OUT="$(bash "$RUN_SUMMARY" 2>&1)"
check_eq "no output" "$OUT" ""

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
