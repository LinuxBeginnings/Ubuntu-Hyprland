#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks update-deps.sh's summary against a synthetic final-check log: the
# status lines the check prints (Hyprland source, Quickshell version note) must
# not be counted as missing packages, and the Hyprland state must come from the
# shared helpers.
#
# Every script update-deps.sh would run is replaced by a no-op, so nothing is
# installed and no sudo is needed.
#
# Usage: ./tests/update-deps-summary-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE="$ROOT/install-scripts/update-deps.sh"
LOGS="$ROOT/Install-Logs"

[ -f "$UPDATE" ] || {
    echo "cannot find install-scripts/update-deps.sh" >&2
    exit 1
}

WORK="$(mktemp -d)" || {
    echo "cannot create a temp directory" >&2
    exit 1
}

# update-deps.sh writes its own logs and reads the newest final-check log;
# remember what already existed so only this test's artifacts are removed.
shopt -s nullglob
pre_logs=("$LOGS"/update-deps-* "$LOGS"/00_CHECK-*_installed.log)
shopt -u nullglob

cleanup() {
    local f keep e
    for f in "$LOGS"/update-deps-* "$LOGS"/00_CHECK-*_installed.log; do
        [ -e "$f" ] || continue
        keep=0
        for e in "${pre_logs[@]}"; do
            [ "$f" = "$e" ] && keep=1
        done
        [ "$keep" -eq 1 ] || rm -f "$f"
    done
    rm -rf "$WORK"
}
trap cleanup EXIT

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
    *) fail "$1" "'$3' not in: $(printf '%s' "$2" | grep -F "Missing packages" | head -1)" ;;
    esac
}

# ─── fixtures ───────────────────────────────────────────────────────────────
mkdir -p "$LOGS"
mkdir -p "$WORK/ppa"
printf 'deb https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/ zzz-not-a-release main\n' \
    >"$WORK/ppa/cppiber-ubuntu-hyprland-zzz.list"
printf 'ubuntu\tthe PPA is enabled for zzz-not-a-release, this system runs somewhere-else\n' \
    >"$WORK/record.txt"

STUB="$WORK/stub.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB"
chmod +x "$STUB"

check_log="$LOGS/00_CHECK-$(date +%d-%H%M%S)_installed.log"
{
    printf 'hyprland\n'
    printf 'waybar (source build)\n'
    printf '[INFO] Hyprland came from the Ubuntu repositories.\n'
    printf '[WARN] The community PPA path was not used: the PPA is enabled for noble, this system runs resolute.\n'
    printf '[OK] Quickshell 0.3.0 meets the minimum 0.3.0.\n'
    printf '[NOTE] Missing packages logged at now\n'
} >"$check_log"

out="$(
    APT_SOURCES_DIR="$WORK/ppa" \
        HYPRLAND_SOURCE_FILE="$WORK/record.txt" \
        DEPENDENCIES_SCRIPT="$STUB" \
        PACKAGES_SCRIPT="$STUB" \
        YAZI_SCRIPT="$STUB" \
        SWWW_SCRIPT="$STUB" \
        NWG_DOCK_SCRIPT="$STUB" \
        WAYBAR_SCRIPT="$STUB" \
        QUICKSHELL_SCRIPT="$STUB" \
        CHECK_SCRIPT="$STUB" \
        "$UPDATE" 2>&1
)"
status=$?

echo
echo "update-deps.sh summary"
check_eq "exits 0" "$status" "0"
check_contains "only real packages are missing" "$out" "Missing packages from final check (2): hyprland waybar (source build)"
check_contains "Hyprland source comes from the record" "$out" "Hyprland: installed from the Ubuntu repositories (PPA path not used:"
check_contains "PPA state comes from the helpers" "$out" "Hyprland PPA: enabled for zzz-not-a-release"
check_contains "summary still reports success" "$out" "All steps completed successfully."

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
