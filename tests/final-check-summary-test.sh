#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks the Hyprland source summary in 03-Final-Check.sh: which path the
# record says Hyprland came from, and whether the recorded reason is repeated.
#
# The summary block is extracted from the final check and run against a scratch
# record file (HYPRLAND_SOURCE_FILE), so the checks in the rest of the script
# never run and nothing on the system is touched.
#
# Usage: ./tests/final-check-summary-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FINAL="$ROOT/install-scripts/03-Final-Check.sh"
FUNCTIONS="$ROOT/install-scripts/Global_functions.sh"

[ -f "$FINAL" ] || {
    echo "cannot find install-scripts/03-Final-Check.sh" >&2
    exit 1
}
[ -f "$FUNCTIONS" ] || {
    echo "cannot find install-scripts/Global_functions.sh" >&2
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

check_eq() {
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1" "expected [$3], got [$2]"
    fi
}

# ─── extract the summary block ─────────────────────────────────────────────
BLOCK="$WORK/summary.sh"
awk '
    /^hypr_src="\$\(hyprland_source_field 1\)"$/ { on = 1 }
    on && /^# Log missing packages/ { exit }
    on
' "$FINAL" >"$BLOCK"

if ! grep -q 'hyprland_source_field' "$BLOCK" || ! grep -q 'ppa-failed' "$BLOCK"; then
    echo "could not extract the Hyprland summary block from 03-Final-Check.sh" >&2
    exit 1
fi

RUN="$WORK/run.sh"
{
    printf '%s\n' '#!/usr/bin/env bash' 'set -uo pipefail'
    printf 'GF_SKIP_SETUP=1 GF_STRICT=0 . %q\n' "$FUNCTIONS"
    cat "$BLOCK"
} >"$RUN"

bash -n "$RUN" || {
    echo "extracted summary block is not runnable" >&2
    exit 1
}

RECORD="$WORK/hyprland-source.txt"
export HYPRLAND_SOURCE_FILE="$RECORD"

record() { printf '%s\t%s\n' "$1" "${2:-}" >"$RECORD"; }
summary() { bash "$RUN" 2>&1; }

PPA_REASON="PPA is enabled for questing, but this system runs resolute"

echo
echo "no record yet"
rm -f "$RECORD"
check_eq "prints nothing" "$(summary)" ""

echo
echo "Hyprland came from the PPA"
record ppa
out="$(summary)"
check_contains "names the community PPA" "$out" "Hyprland came from the community"
check_contains "names the PPA itself" "$out" "PPA"
check_lacks "no reason line" "$out" "The community PPA path"

echo
echo "a recorded reason is not repeated for a working PPA"
record ppa "$PPA_REASON"
check_lacks "reason stays hidden" "$(summary)" "$PPA_REASON"

echo
echo "Hyprland fell back to the Ubuntu repositories"
record ubuntu "$PPA_REASON"
out="$(summary)"
check_contains "names the Ubuntu repositories" "$out" "Hyprland came from the"
check_contains "names Ubuntu" "$out" "Ubuntu repositories"
check_contains "explains why the PPA was skipped" "$out" "The community PPA path was not used: $PPA_REASON."

echo
echo "Ubuntu repositories without a recorded reason"
record ubuntu
out="$(summary)"
check_contains "still names Ubuntu" "$out" "Ubuntu repositories"
check_lacks "no reason line" "$out" "The community PPA path was not used"

echo
echo "the PPA path failed outright"
record ppa-failed "$PPA_REASON"
check_contains "says the PPA provided nothing" "$(summary)" "The community PPA path did not provide Hyprland: $PPA_REASON."

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
