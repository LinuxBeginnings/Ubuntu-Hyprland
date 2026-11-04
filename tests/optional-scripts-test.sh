#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks that optional components no longer abort the install: a failing
# optional script warns, the run continues, and the failures are listed once at
# the end. Also checks that an unknown install mode is rejected before any work.
#
# The `run_optional` helper and the final summary are extracted from install.sh
# and run against a stubbed execute_script, so nothing is installed.
#
# Usage: ./tests/optional-scripts-test.sh

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

# ─── extract run_optional and the closing summary ──────────────────────────
awk '/^failed_optional=\(\)$/ { on = 1 } on { print } on && /^}$/ { exit }' \
    "$INSTALL" >"$WORK/helper.sh"
awk '/^# Optional components that failed are listed once here/ { on = 1 }
     on { print }
     on && /^fi$/ { exit }' "$INSTALL" >"$WORK/summary.sh"

if ! grep -q 'run_optional()' "$WORK/helper.sh" ||
    ! grep -q 'did not install' "$WORK/summary.sh"; then
    echo "could not extract run_optional / the optional summary from install.sh" >&2
    exit 1
fi

RUN="$WORK/run.sh"
{
    printf '%s\n' '#!/usr/bin/env bash' 'set -uo pipefail'
    printf 'LOG=%q\n' "$WORK/install.log"
    printf '%s\n' 'INFO="[INFO]"; WARN="[WARN]"; NOTE="[NOTE]"'
    cat <<'STUB'
execute_script() {
    if [ -f "$STUB_DIR/$1.status" ]; then
        return "$(cat "$STUB_DIR/$1.status")"
    fi
    return 0
}
STUB
    cat "$WORK/helper.sh"
    printf '%s\n' 'for s in "$@"; do run_optional "$s"; done'
    cat "$WORK/summary.sh"
    printf '%s\n' 'if [ ${#failed_optional[@]} -gt 0 ]; then'
    printf '%s\n' '    printf "FAILED: %s\n" "${failed_optional[*]}"'
    printf '%s\n' 'fi'
} >"$RUN"

bash -n "$RUN" || {
    echo "extracted optional-component harness is not runnable" >&2
    exit 1
}

run_case() { # run_case <case> <script> <status>
    local dir="$WORK/$1"
    mkdir -p "$dir"
    printf '%s' "$3" >"$dir/$2.status"
    STUB_DIR="$dir" bash "$RUN" "$2" >"$dir/output" 2>&1
}

output() { cat "$WORK/$1/output" 2>/dev/null; }

echo
echo "an optional script fails"
run_case failing yazi.sh 1
check_eq "install continues" "$?" "0"
check_contains "warns about it" "$(output failing)" "[WARN] yazi.sh failed"
check_contains "says it continues" "$(output failing)" "continuing without it"
check_contains "summary names the component" "$(output failing)" "did not install"
check_contains "summary lists it" "$(output failing)" "- yazi.sh"
check_contains "failure is recorded" "$(output failing)" "FAILED: yazi.sh"

echo
echo "an optional script succeeds"
run_case ok wallust.sh 0
check_eq "install continues" "$?" "0"
check_lacks "no warning" "$(output ok)" "failed"
check_lacks "nothing recorded" "$(output ok)" "FAILED:"
check_lacks "no summary" "$(output ok)" "did not install"

echo
echo "two optional scripts fail"
mkdir -p "$WORK/two"
printf '1' >"$WORK/two/sddm.sh.status"
printf '1' >"$WORK/two/thunar.sh.status"
STUB_DIR="$WORK/two" bash "$RUN" sddm.sh thunar.sh >"$WORK/two/output" 2>&1
check_eq "install continues" "$?" "0"
check_contains "both are recorded" "$(output two)" "FAILED: sddm.sh thunar.sh"
check_contains "both are listed" "$(output two)" "- thunar.sh"

echo
echo "an unknown install mode is rejected before any work"
awk '/^# Reject an unknown mode here/ { on = 1 } on { print } on && /^esac$/ { exit }' \
    "$INSTALL" >"$WORK/mode.sh"
MODE_RUN="$WORK/mode-run.sh"
{
    printf '%s\n' '#!/usr/bin/env bash' 'set -uo pipefail'
    cat "$WORK/mode.sh"
} >"$MODE_RUN"
bash -n "$MODE_RUN" || {
    echo "extracted install-mode guard is not runnable" >&2
    exit 1
}
INSTALL_MODE=bogus bash "$MODE_RUN" >"$WORK/mode-bad" 2>&1
check_eq "unknown mode exits 1" "$?" "1"
check_contains "names the mode" "$(cat "$WORK/mode-bad")" "Unknown install mode: bogus"
INSTALL_MODE=ubuntu bash "$MODE_RUN" >/dev/null 2>&1
check_eq "a known mode passes" "$?" "0"

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
