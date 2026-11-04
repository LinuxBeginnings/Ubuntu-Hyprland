#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks that install-scripts/ags.sh fails the step when the build or install
# fails. It used to print "Installation failed" and exit 0, so install.sh
# treated a broken ags as installed.
#
# ags.sh runs in a throwaway copy of the repo with stubbed git/npm/meson/sudo
# ahead of the real PATH: nothing is cloned, compiled or installed, and the
# sudo stub never runs its command at all. A real build still has to be run on a
# machine; this pins the control flow.
#
# Usage: ./tests/ags-install-failure-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGS="$ROOT/install-scripts/ags.sh"
GLOBALS="$ROOT/install-scripts/Global_functions.sh"

for f in "$AGS" "$GLOBALS"; do
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
    *) fail "$1" "'$3' not in: $(printf '%s' "$2" | tail -3 | tr '\n' ' ')" ;;
    esac
}

check_lacks() {
    case "$2" in
    *"$3"*) fail "$1" "'$3' unexpectedly present" ;;
    *) pass "$1" ;;
    esac
}

# ─── sandbox: a repo whose Global_functions.sh makes ags.sh build here ──────
REPO="$WORK/repo"
mkdir -p "$REPO/install-scripts" "$WORK/stub"
cp "$AGS" "$REPO/install-scripts/ags.sh"
cp "$GLOBALS" "$REPO/install-scripts/Global_functions.sh"

# Each stub reads "<name>.status" from $STUB_DIR, so one sandbox can be reused
# for every case. Callers that must not touch the system exit without running.
cat >"$WORK/stub/sudo" <<'STUB'
#!/usr/bin/env bash
# sudo stub: never runs its command. Only `meson install` can report a status.
if [ "${1:-}" = "meson" ] && [ "${2:-}" = "install" ]; then
    exit "$(cat "$STUB_DIR/meson-install.status" 2>/dev/null || echo 0)"
fi
exit 0
STUB

cat >"$WORK/stub/git" <<'STUB'
#!/usr/bin/env bash
# git stub: only `git clone` is used, and it just creates the directory.
status="$(cat "$STUB_DIR/git.status" 2>/dev/null || echo 0)"
[ "$status" = "0" ] || exit "$status"
mkdir -p ags_v1.9.0
exit 0
STUB

cat >"$WORK/stub/npm" <<'STUB'
#!/usr/bin/env bash
status="$(cat "$STUB_DIR/npm.status" 2>/dev/null || echo 0)"
[ "$status" = "0" ] || exit "$status"
exit 0
STUB

cat >"$WORK/stub/meson" <<'STUB'
#!/usr/bin/env bash
# meson stub: the status depends on the subcommand (setup or install)
status="$(cat "$STUB_DIR/meson-${1:-none}.status" 2>/dev/null || echo 0)"
[ "$status" = "0" ] || exit "$status"
exit 0
STUB

cat >"$WORK/stub/dpkg-query" <<'STUB'
#!/usr/bin/env bash
# dpkg-query stub: report every package as installed, so no apt runs
printf 'Status: install ok installed\n'
STUB

cat >"$WORK/stub/ags" <<'STUB'
#!/usr/bin/env bash
# ags stub: no version output, so the script does not offer to reinstall
exit 0
STUB

chmod +x "$WORK"/stub/*

# run_ags <case> [<stub>=<status> ...] — runs ags.sh in the sandbox and stores
# its output in $WORK/<case>/output
run_ags() {
    local case_name="$1" dir assign
    shift
    dir="$WORK/$case_name"
    mkdir -p "$dir/stub"
    for assign in "$@"; do
        printf '%s' "${assign#*=}" >"$dir/stub/${assign%%=*}.status"
    done
    TERM=dumb STUB_DIR="$dir/stub" PATH="$WORK/stub:$PATH" \
        bash "$REPO/install-scripts/ags.sh" >"$dir/output" 2>&1
}

output() { cat "$WORK/$1/output" 2>/dev/null; }

echo
echo "git clone fails"
run_ags clone-fails git=1
check_eq "exits 1" "$?" "1"
check_contains "reports the download failure" "$(output clone-fails)" "Failed to download"

echo
echo "npm install fails"
run_ags npm-fails npm=1
check_eq "exits 1" "$?" "1"
check_contains "names the npm step" "$(output npm-fails)" "npm install failed"
check_lacks "does not claim a successful install" "$(output npm-fails)" "installed successfully"

echo
echo "meson setup fails"
run_ags setup-fails meson-setup=1
check_eq "exits 1" "$?" "1"
check_contains "names the configure step" "$(output setup-fails)" "meson setup) failed"
check_lacks "does not claim a successful install" "$(output setup-fails)" "installed successfully"

echo
echo "meson install fails"
run_ags install-fails meson-install=1
check_eq "exits 1" "$?" "1"
check_contains "reports the installation failure" "$(output install-fails)" "Installation failed"
check_contains "points at the build log" "$(output install-fails)" "_ags2.log"
check_lacks "does not claim a successful install" "$(output install-fails)" "installed successfully"

echo
echo "everything succeeds"
run_ags success
check_eq "exits 0" "$?" "0"
check_contains "reports success" "$(output success)" "installed successfully"

echo
echo "nothing was written outside the sandbox"
if [ -d "$REPO/build/src/ags_v1.9.0" ]; then
    pass "the clone stayed in the sandbox"
else
    fail "the clone stayed in the sandbox" "no source directory was created"
fi

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
