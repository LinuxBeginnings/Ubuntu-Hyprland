#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks that `install.sh --dry-run` reports the PPA-vs-Ubuntu verdict, never
# prompts and never writes anything. The dry-run path exits before any package
# work, so this needs no sudo.
#
# Usage: ./tests/install-dry-run-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$ROOT/install.sh"
GLOBALS="$ROOT/install-scripts/Global_functions.sh"

for f in "$INSTALL" "$GLOBALS"; do
    [ -f "$f" ] || {
        echo "cannot find ${f#"$ROOT"/}" >&2
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
    *) fail "$1" "'$3' not in: $(printf '%s' "$2" | head -3 | tr '\n' ' ')" ;;
    esac
}

check_lacks() {
    case "$2" in
    *"$3"*) fail "$1" "'$3' unexpectedly present" ;;
    *) pass "$1" ;;
    esac
}

# The codename the installer itself will compare against. Empty on systems
# without /etc/os-release, in which case the "match" case is skipped.
codename="$(GF_STRICT=0 GF_SKIP_SETUP=1 bash -c '. '"$GLOBALS"'; ubuntu_codename' 2>/dev/null)"

# ─── fixtures: PPA source files ─────────────────────────────────────────────
OTHER="not-a-real-release"
mkdir -p "$WORK/other" "$WORK/match" "$WORK/empty"
printf 'deb https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/ %s main\n' "$OTHER" \
    >"$WORK/other/cppiber-ubuntu-hyprland-$OTHER.list"
if [ -n "$codename" ]; then
    printf 'Types: deb\nURIs: https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/\nSuites: %s\nComponents: main\n' "$codename" \
        >"$WORK/match/cppiber-ubuntu-hyprland-$codename.sources"
fi

dryrun() { # dryrun <sources-dir> [options...]
    APT_SOURCES_DIR="$1" bash "$INSTALL" "${@:2}" 2>&1
}

echo
echo "dry run with a PPA that does not cover this release"
out="$(dryrun "$WORK/other" --dry-run --install-ppa)"
check_eq "exits 0" "$?" "0"
check_contains "would run the PPA script" "$out" "hyprland-ppa.sh"
check_contains "names the PPA series" "$out" "PPA is enabled for ${OTHER}"
check_contains "points at --install-ubuntu" "$out" "use --install-ubuntu"
check_lacks "never prompts" "$out" "Do you still want to continue"

if [ -n "$codename" ]; then
    echo
    echo "dry run with a PPA that covers this release ($codename)"
    out="$(dryrun "$WORK/match" --dry-run --install-ppa)"
    check_eq "exits 0" "$?" "0"
    check_contains "reports coverage" "$out" "PPA covers this release (${codename})"
else
    echo
    echo "dry run with a PPA that covers this release (skipped: codename unknown)"
fi

echo
echo "dry run without a PPA and in Ubuntu mode"
out="$(dryrun "$WORK/empty" --dry-run --install-ppa)"
check_eq "no PPA exits 0" "$?" "0"
check_contains "no PPA is stated" "$out" "No Hyprland PPA enabled yet"

out="$(dryrun "$WORK/empty" --dry-run --install-ubuntu)"
check_eq "ubuntu mode exits 0" "$?" "0"
check_contains "would run the Ubuntu script" "$out" "hyprland-ubuntu.sh"
check_lacks "ubuntu mode makes no PPA claim" "$out" "PPA is enabled for"

echo
echo "dry run writes nothing"
out="$(bash "$INSTALL" --help 2>&1)"
check_contains "--help documents --install-ubuntu" "$out" "--install-ubuntu"

record="$ROOT/Install-Logs/hyprland-source.txt"
if [ -f "$record" ]; then
    before="$(cksum <"$record")"
else
    before="absent"
fi
dryrun "$WORK/other" --dry-run --install-ppa >/dev/null 2>&1
if [ -f "$record" ]; then
    after="$(cksum <"$record")"
else
    after="absent"
fi
check_eq "Hyprland source record untouched" "$after" "$before"

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
