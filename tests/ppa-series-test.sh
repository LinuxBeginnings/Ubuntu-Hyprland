#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks the Hyprland PPA series guard (ppa_series_ok / ppa_suites) against
# fixture APT source files, in both the one-line and the deb822 format, and
# checks the Hyprland source record the final check reads back. It installs
# nothing and needs no sudo.
#
# Usage: ./tests/ppa-series-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBALS="$ROOT/install-scripts/Global_functions.sh"

if [ ! -f "$GLOBALS" ]; then
    echo "cannot find install-scripts/Global_functions.sh" >&2
    exit 1
fi

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

# Pull a single function definition out of a script.
extract_fn() { # extract_fn <file> <function>
    awk -v fn="$2" '
        !on && $0 ~ "^" fn "\\(\\) \\{" { on = 1 }
        on { print }
        on && /^\}/ { exit }
    ' "$1"
}

FUNCS="$WORK/funcs.sh"
: >"$FUNCS"
for fn in ubuntu_codename ppa_suites ppa_series_ok \
    hyprland_source_file record_hyprland_source hyprland_source_field; do
    body="$(extract_fn "$GLOBALS" "$fn")"
    if [ -z "$body" ]; then
        echo "could not extract $fn from install-scripts/Global_functions.sh" >&2
        exit 1
    fi
    printf '%s\n' "$body" >>"$FUNCS"
done
# shellcheck source=/dev/null
. "$FUNCS"

# ─── fixture: APT source layouts ────────────────────────────────────────────
FIX="$WORK/sources"
mkdir -p "$FIX/list-match" "$FIX/list-mismatch" "$FIX/deb822-match" \
    "$FIX/deb822-mismatch" "$FIX/decoy" "$FIX/empty"

# add-apt-repository writes this one-line form on releases that still use it
printf 'deb [arch=amd64 signed-by=/etc/apt/keyrings/x.gpg] https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/ resolute main\n' \
    >"$FIX/list-match/cppiber-ubuntu-hyprland-resolute.list"
printf 'deb-src https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/ resolute main\n' \
    >>"$FIX/list-match/cppiber-ubuntu-hyprland-resolute.list"
printf 'deb https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/ noble main\n' \
    >"$FIX/list-mismatch/cppiber-ubuntu-hyprland-noble.list"

# current Ubuntu releases get the deb822 form
printf 'Types: deb\nURIs: https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/\nSuites: resolute\nComponents: main\n' \
    >"$FIX/deb822-match/cppiber-ubuntu-hyprland-resolute.sources"
printf 'Types: deb\nURIs: https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/\nSuites: noble\nComponents: main\n' \
    >"$FIX/deb822-mismatch/cppiber-ubuntu-hyprland-noble.sources"

# an unrelated repository must never be mistaken for the PPA
printf 'deb http://archive.ubuntu.com/ubuntu noble main\n' >"$FIX/decoy/other.list"

# The helpers read APT_SOURCES_DIR from the environment; exporting it keeps the
# fixture path visible to shellcheck and to the extracted functions.
suites() {
    export APT_SOURCES_DIR="$1"
    ppa_suites
}
verdict() { # verdict <dir> <codename> -> ok|blocked
    export APT_SOURCES_DIR="$1"
    if ppa_series_ok "$2"; then echo ok; else echo blocked; fi
}

echo
echo "ppa_suites: read the series the PPA is enabled for"
check_eq "one-line form" "$(suites "$FIX/list-match")" "resolute"
check_eq "deb822 form" "$(suites "$FIX/deb822-mismatch")" "noble"
check_eq "unrelated repository ignored" "$(suites "$FIX/decoy")" ""
check_eq "no sources at all" "$(suites "$FIX/empty")" ""

echo
echo "ppa_series_ok: only a real suite mismatch blocks the install"
check_eq "one-line form matches" "$(verdict "$FIX/list-match" resolute)" "ok"
check_eq "one-line form mismatches" "$(verdict "$FIX/list-mismatch" resolute)" "blocked"
check_eq "deb822 form matches" "$(verdict "$FIX/deb822-match" resolute)" "ok"
check_eq "deb822 form mismatches" "$(verdict "$FIX/deb822-mismatch" resolute)" "blocked"

echo
echo "ppa_series_ok: unknown state does not block"
check_eq "no PPA sources" "$(verdict "$FIX/empty" resolute)" "ok"
check_eq "unknown codename" "$(verdict "$FIX/list-mismatch" "")" "ok"

echo
echo "hyprland source record round-trip"
STATE="$WORK/hyprland-source.txt"
export HYPRLAND_SOURCE_FILE="$STATE"

record_hyprland_source ppa-failed "apt update failed"
check_eq "outcome stored" "$(hyprland_source_field 1)" "ppa-failed"
check_eq "reason stored" "$(hyprland_source_field 2)" "apt update failed"

record_hyprland_source ubuntu
check_eq "outcome rewritten" "$(hyprland_source_field 1)" "ubuntu"
check_eq "stale reason cleared" "$(hyprland_source_field 2)" ""

rm -f "$STATE"
check_eq "missing record, outcome empty" "$(hyprland_source_field 1)" ""
check_eq "missing record, reason empty" "$(hyprland_source_field 2)" ""

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
