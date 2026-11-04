#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks that the source-build scripts fail their step when the build or the
# install fails. They used to print "Installation failed" and exit 0, so
# install.sh treated a broken component as installed.
#
# Covered: ags.sh (clone, npm install, meson setup, meson install, success),
# hyprlock.sh (clone, cmake --install), hypridle.sh (cmake --install) and rog.sh
# (one project failing while the other still installs).
#
# The scripts run in a throwaway copy of the repo with stubbed
# git/npm/meson/cmake/make/curl/pkg-config/dpkg-query/sudo ahead of the real
# PATH: nothing is cloned, compiled or installed, and the sudo stub never runs
# its command at all. A real build still has to be run on a machine; this pins
# the control flow.
#
# Usage: ./tests/source-install-failure-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$ROOT/install-scripts"

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

# ─── sandbox: a repo whose Global_functions.sh makes the scripts build here ──
REPO="$WORK/repo"
mkdir -p "$REPO/install-scripts" "$WORK/stub" "$WORK/home/.cargo"
: >"$WORK/home/.cargo/env"

for f in ags.sh hyprlock.sh hypridle.sh rog.sh Global_functions.sh Global_versions.sh; do
    [ -f "$SCRIPTS/$f" ] || {
        echo "cannot find $SCRIPTS/$f" >&2
        exit 1
    }
    cp "$SCRIPTS/$f" "$REPO/install-scripts/$f"
done

# Each stub reads "<name>.status" from $STUB_DIR, so one sandbox is reused for
# every case. Stubs that must not touch the system exit without running: the
# sudo stub is the only one that would have changed anything.
cat >"$WORK/stub/sudo" <<'STUB'
#!/usr/bin/env bash
# sudo stub: never runs its command. The exit status comes from
# "<cmd>-<install|setup>.status", optionally narrowed by the directory the
# command runs in (rog runs `make install` inside each cloned project).
cmd="${1:-}"
shift || true
sub=""
for arg in "$@"; do
    case "${arg#--}" in
    install|setup)
        sub="${arg#--}"
        break
        ;;
    esac
done
[ -n "$sub" ] || exit 0
for f in "$STUB_DIR/$cmd-$sub-$(basename "$PWD").status" "$STUB_DIR/$cmd-$sub.status"; do
    [ -f "$f" ] && exit "$(cat "$f")"
done
exit 0
STUB

cat >"$WORK/stub/git" <<'STUB'
#!/usr/bin/env bash
# git stub: only `git clone` is used. It creates the destination directory and
# downloads nothing.
status="$(cat "$STUB_DIR/git.status" 2>/dev/null || echo 0)"
[ "$status" = "0" ] || exit "$status"
dest=""
for arg in "$@"; do
    case "$arg" in
    -* | clone) ;;
    *) dest="$arg" ;;
    esac
done
[ -n "$dest" ] || exit 0
case "$dest" in
*://*)
    # `git clone <url>` with no destination: derive it from the URL
    name="${dest%/}"
    name="${name##*/}"
    dest="${name%.git}"
    ;;
esac
mkdir -p "$dest"
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

cat >"$WORK/stub/cmake" <<'STUB'
#!/usr/bin/env bash
# cmake stub: configure and build succeed; only the install step, which goes
# through the sudo stub, can report a status.
exit 0
STUB

cat >"$WORK/stub/make" <<'STUB'
#!/usr/bin/env bash
# make stub: the build succeeds; `make install` goes through the sudo stub.
exit 0
STUB

cat >"$WORK/stub/curl" <<'STUB'
#!/usr/bin/env bash
# curl stub: prints nothing, so the rustup installer piped to sh does nothing.
exit 0
STUB

cat >"$WORK/stub/pkg-config" <<'STUB'
#!/usr/bin/env bash
# pkg-config stub: report the hypr* headers as present, so no apt runs.
exit 0
STUB

cat >"$WORK/stub/dpkg-query" <<'STUB'
#!/usr/bin/env bash
# dpkg-query stub: report every package as installed, so no apt runs, and carry
# no version number, so the version guards build instead of skipping.
printf 'Status: install ok installed\n'
STUB

for bin in ags hyprlock hypridle; do
    cat >"$WORK/stub/$bin" <<'STUB'
#!/usr/bin/env bash
# binary stub: no version output, so the script does not skip the build
exit 0
STUB
done

chmod +x "$WORK"/stub/*

# run_script <case> <script> [<stub>=<status> ...] — runs a script in the
# sandbox and stores its output in $WORK/<case>/output
run_script() {
    local case_name="$1" script="$2" dir assign
    shift 2
    dir="$WORK/$case_name"
    mkdir -p "$dir/stub"
    for assign in "$@"; do
        printf '%s' "${assign#*=}" >"$dir/stub/${assign%%=*}.status"
    done
    TERM=dumb HOME="$WORK/home" STUB_DIR="$dir/stub" PATH="$WORK/stub:$PATH" \
        bash "$REPO/install-scripts/$script" >"$dir/output" 2>&1
}

output() { cat "$WORK/$1/output" 2>/dev/null; }

echo
echo "ags: git clone fails"
run_script ags-clone-fails ags.sh git=1
check_eq "exits 1" "$?" "1"
check_contains "reports the download failure" "$(output ags-clone-fails)" "Failed to download"

echo
echo "ags: npm install fails"
run_script ags-npm-fails ags.sh npm=1
check_eq "exits 1" "$?" "1"
check_contains "names the npm step" "$(output ags-npm-fails)" "npm install failed"
check_lacks "does not claim a successful install" "$(output ags-npm-fails)" "installed successfully"

echo
echo "ags: meson setup fails"
run_script ags-setup-fails ags.sh meson-setup=1
check_eq "exits 1" "$?" "1"
check_contains "names the configure step" "$(output ags-setup-fails)" "meson setup) failed"
check_lacks "does not claim a successful install" "$(output ags-setup-fails)" "installed successfully"

echo
echo "ags: meson install fails"
run_script ags-install-fails ags.sh meson-install=1
check_eq "exits 1" "$?" "1"
check_contains "reports the installation failure" "$(output ags-install-fails)" "Installation failed"
check_contains "points at the build log" "$(output ags-install-fails)" "_ags2.log"
check_lacks "does not claim a successful install" "$(output ags-install-fails)" "installed successfully"

echo
echo "ags: everything succeeds"
run_script ags-success ags.sh
check_eq "exits 0" "$?" "0"
check_contains "reports success" "$(output ags-success)" "installed successfully"

echo
echo "hyprlock: git clone fails"
run_script hyprlock-clone-fails hyprlock.sh git=1
check_eq "exits 1" "$?" "1"
check_contains "reports the download failure" "$(output hyprlock-clone-fails)" "Download failed for"
check_lacks "does not claim a successful install" "$(output hyprlock-clone-fails)" "installed successfully"

echo
echo "hyprlock: cmake --install fails"
run_script hyprlock-install-fails hyprlock.sh cmake-install=1
check_eq "exits 1" "$?" "1"
check_contains "reports the installation failure" "$(output hyprlock-install-fails)" "Installation failed for"
check_contains "points at the build log" "$(output hyprlock-install-fails)" "_hyprlock2.log"
check_lacks "does not claim a successful install" "$(output hyprlock-install-fails)" "installed successfully"

echo
echo "hypridle: cmake --install fails"
run_script hypridle-install-fails hypridle.sh cmake-install=1
check_eq "exits 1" "$?" "1"
check_contains "reports the installation failure" "$(output hypridle-install-fails)" "Installation failed for"
check_contains "points at the build log" "$(output hypridle-install-fails)" "_hypridle2.log"
check_lacks "does not claim a successful install" "$(output hypridle-install-fails)" "installed successfully"

echo
echo "rog: the first project fails to install"
run_script rog-install-fails rog.sh make-install-asusctl=1
check_eq "exits 1" "$?" "1"
check_contains "reports the asusctl failure" "$(output rog-install-fails)" "asusctl"
check_lacks "does not claim asusctl installed" "$(output rog-install-fails)" "asusctl installed successfully"
check_contains "still installs the second project" "$(output rog-install-fails)" "supergfxctl installed successfully"

echo
echo "nothing was written outside the sandbox"
if [ -d "$REPO/build/src/ags_v1.9.0" ] &&
    [ -d "$REPO/build/src/hyprlock" ] &&
    [ -d "$REPO/build/src/hypridle" ] &&
    [ -d "$REPO/asusctl" ] &&
    [ -d "$REPO/supergfxctl" ]; then
    pass "every clone stayed in the sandbox"
else
    fail "every clone stayed in the sandbox" "a clone is missing from the sandbox"
fi

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
