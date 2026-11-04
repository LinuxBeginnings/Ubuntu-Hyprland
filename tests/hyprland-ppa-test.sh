#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Runs the real hyprland-ppa.sh against stubbed sudo/apt/apt-cache so its four
# outcomes (series mismatch, failed apt update, no candidate, success) and the
# Hyprland source record they write are covered without root or a real system.
#
# Usage: ./tests/hyprland-ppa-test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/install-scripts/hyprland-ppa.sh"
GLOBALS="$ROOT/install-scripts/Global_functions.sh"

for f in "$SCRIPT" "$GLOBALS"; do
    [ -f "$f" ] || {
        echo "cannot find ${f#"$ROOT"/}" >&2
        exit 1
    }
done

WORK="$(mktemp -d)" || {
    echo "cannot create a temp directory" >&2
    exit 1
}

# The script writes its own log through init_script; remember what already
# existed so only this test's logs are removed.
shopt -s nullglob
pre_logs=("$ROOT"/Install-Logs/install-*_hyprland-ppa*.log)
shopt -u nullglob

cleanup() {
    local f keep e
    for f in "$ROOT"/Install-Logs/install-*_hyprland-ppa*.log; do
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
    *) fail "$1" "'$3' not in: $(printf '%s' "$2" | head -2 | tr '\n' ' ')" ;;
    esac
}

# ─── stubs ──────────────────────────────────────────────────────────────────
STUB="$WORK/bin"
mkdir -p "$STUB"

cat >"$STUB/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

# `apt update` can be made to fail; every other apt call succeeds
cat >"$STUB/apt" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = update ] && [ "${APT_UPDATE_EXIT:-0}" != "0" ]; then
    echo "Err:1 fake repository failure" >&2
    exit 1
fi
echo "fake apt $*"
exit 0
EOF

# `apt-cache policy` in candidate / no-candidate / unknown-package flavours
cat >"$STUB/apt-cache" <<'EOF'
#!/usr/bin/env bash
[ "${1:-}" = policy ] || exit 1
pkg="${2:-}"
case "${APT_CACHE_MODE:-candidate}" in
candidate) printf '%s:\n  Installed: (none)\n  Candidate: 1.0-1\n' "$pkg" ;;
none) printf '%s:\n  Installed: (none)\n  Candidate: (none)\n' "$pkg" ;;
esac
EOF

# writes the PPA source file the script then inspects
cat >"$STUB/add-apt-repository" <<'EOF'
#!/usr/bin/env bash
suite="${PPA_STUB_SUITE:-noble}"
printf 'deb https://ppa.launchpadcontent.net/cppiber/hyprland/ubuntu/ %s main\n' "$suite" \
    >"$APT_SOURCES_DIR/cppiber-ubuntu-hyprland-$suite.list"
EOF

# everything already installed, so install_package skips apt
cat >"$STUB/dpkg-query" <<'EOF'
#!/usr/bin/env bash
echo "install ok installed"
EOF

chmod +x "$STUB"/*

# The codename the script compares against.
codename="$(GF_STRICT=0 GF_SKIP_SETUP=1 bash -c '. '"$GLOBALS"'; ubuntu_codename' 2>/dev/null)"

run_ppa() { # run_ppa <case> [env assignments...]
    local case_dir="$WORK/$1"
    shift
    mkdir -p "$case_dir/sources"
    env PATH="$STUB:$PATH" \
        APT_SOURCES_DIR="$case_dir/sources" \
        HYPRLAND_SOURCE_FILE="$case_dir/record.txt" \
        PPA_STUB_SUITE="${codename:-any-release}" \
        "$@" \
        bash "$SCRIPT" >"$case_dir/output.txt" 2>&1
}

outcome() { # outcome <case> -> field 1 of the record
    cut -f1 "$WORK/$1/record.txt" 2>/dev/null
}

reason() { # reason <case> -> field 2 of the record
    cut -f2 "$WORK/$1/record.txt" 2>/dev/null
}

echo
echo "a PPA enabled for another series is refused and recorded"
if [ -n "$codename" ]; then
    run_ppa mismatch PPA_STUB_SUITE="not-a-real-release"
    check_eq "exits 1" "$?" "1"
    check_eq "recorded as ppa-failed" "$(outcome mismatch)" "ppa-failed"
    check_contains "reason names both series" "$(reason mismatch)" "this system runs ${codename}"
    check_contains "output points at --install-ubuntu" "$(cat "$WORK/mismatch/output.txt")" "Use --install-ubuntu"
else
    echo "  skip (codename unknown on this system)"
fi

echo
echo "a failed apt update is recorded and stops the run"
run_ppa update-failed APT_UPDATE_EXIT=1
check_eq "exits 1" "$?" "1"
check_eq "recorded as ppa-failed" "$(outcome update-failed)" "ppa-failed"
check_eq "reason is the apt update" "$(reason update-failed)" "apt update failed"

echo
echo "a PPA without a hyprland candidate is recorded"
run_ppa no-candidate APT_CACHE_MODE=none
check_eq "exits 1" "$?" "1"
check_eq "recorded as ppa-failed" "$(outcome no-candidate)" "ppa-failed"
check_eq "reason is the missing candidate" "$(reason no-candidate)" "the PPA has no hyprland candidate for this release"

echo
echo "a usable PPA records the source"
run_ppa success
check_eq "exits 0" "$?" "0"
check_eq "recorded as ppa" "$(outcome success)" "ppa"
check_eq "no reason recorded" "$(reason success)" ""

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
