#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# The Hyprland PPA only carries builds for the series it was enabled for, so
# hyprland-ppa.sh checks the series before running apt. These tests exercise
# ppa_suites / ppa_series_ok against source-list fixtures instead of the live
# system: both the one-line (.list) and the deb822 (.sources) form, an unknown
# codename, and no PPA files at all.
#
# Usage: ./tests/ppa-series-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBALS="$ROOT/install-scripts/Global_functions.sh"

[ -f "$GLOBALS" ] || {
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

check_eq() {
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1" "expected [$3], got [$2]"
    fi
}

FUNCS="$WORK/funcs.sh"
: >"$FUNCS"
for fn in ppa_suites ppa_series_ok ubuntu_codename; do
    body="$(awk -v fn="$fn" '
        !on && index($0, fn "() {") == 1 { on = 1 }
        on { print }
        on && /^\}/ { exit }
    ' "$GLOBALS")"
    if [ -z "$body" ]; then
        echo "could not extract $fn from install-scripts/Global_functions.sh" >&2
        exit 1
    fi
    printf '%s\n' "$body" >>"$FUNCS"
done

# The functions read APT_SOURCES_DIR at call time, so each case just repoints it.
# It is exported because the functions that read it live in the sourced file.
export APT_SOURCES_DIR
# shellcheck source=/dev/null
. "$FUNCS"

mkdir -p "$WORK/list" "$WORK/sources" "$WORK/both" "$WORK/empty" "$WORK/plain"

cat >"$WORK/list/cppiber-ubuntu-hyprland.list" <<'EOF'
# added by add-apt-repository for ppa:cppiber/hyprland
deb [arch=amd64 signed-by=/usr/share/keyrings/x.gpg] https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu noble main
EOF

# An unrelated source file must not contribute series.
cat >"$WORK/list/other.list" <<'EOF'
deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy main
EOF

cat >"$WORK/sources/cppiber-ubuntu-hyprland.sources" <<'EOF'
Types: deb
URIs: https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu
Suites: noble
Components: main
EOF

cp "$WORK/list/cppiber-ubuntu-hyprland.list" "$WORK/both/"
sed 's/noble/jammy/' "$WORK/list/cppiber-ubuntu-hyprland.list" >"$WORK/both/cppiber-jammy-hyprland.list"
cp "$WORK/sources/cppiber-ubuntu-hyprland.sources" "$WORK/both/"

cat >"$WORK/plain/cppiber-ubuntu-hyprland.list" <<'EOF'
deb https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu noble main
EOF

echo
echo "the series is read from both source formats"
APT_SOURCES_DIR="$WORK/list"
check_eq "one-line .list" "$(ppa_suites | tr '\n' ' ' | sed 's/ $//')" "noble"
APT_SOURCES_DIR="$WORK/plain"
check_eq "one-line .list without options" "$(ppa_suites)" "noble"
APT_SOURCES_DIR="$WORK/sources"
check_eq "deb822 .sources" "$(ppa_suites)" "noble"

echo
echo "several entries are de-duplicated and sorted"
APT_SOURCES_DIR="$WORK/both"
check_eq "both files" "$(ppa_suites | tr '\n' ' ' | sed 's/ $//')" "jammy noble"

echo
echo "the verdict compares the series with this release"
APT_SOURCES_DIR="$WORK/list"
if ppa_series_ok noble; then pass "matching codename"; else fail "matching codename" "returned non-zero"; fi
if ppa_series_ok jammy; then fail "other codename" "returned zero"; else pass "other codename"; fi
if ppa_series_ok ""; then pass "empty codename means cannot tell"; else fail "empty codename means cannot tell" "returned non-zero"; fi

echo
echo "no PPA source files means cannot tell"
APT_SOURCES_DIR="$WORK/empty"
check_eq "suites are empty" "$(ppa_suites)" ""
if ppa_series_ok noble; then pass "the check does not block"; else fail "the check does not block" "returned non-zero"; fi

echo
echo "the running codename comes from os-release"
expected="$( . /etc/os-release 2>/dev/null && printf '%s' "${VERSION_CODENAME:-}" )"
check_eq "ubuntu_codename" "$(ubuntu_codename)" "$expected"

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
