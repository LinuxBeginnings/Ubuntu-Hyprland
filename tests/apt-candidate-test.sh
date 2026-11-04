#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks has_apt_candidate against a stubbed apt-cache that translates its field
# labels the way apt's translations do. Regression test for the check reporting
# every package as unavailable on non-English systems. Installs nothing and
# needs no sudo.
#
# Usage: ./tests/apt-candidate-test.sh

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

# ─── fixture: a fake apt-cache ──────────────────────────────────────────────
STUB="$WORK/stub"
mkdir -p "$STUB"
cat >"$STUB/apt-cache" <<'STUB_EOF'
#!/usr/bin/env bash
# Stand-in for `apt-cache policy`. Field labels are translated like gettext
# does, unless the C locale is in effect, so a caller that forgets to pin the
# locale cannot match "Candidate:".
[ "${1:-}" = policy ] || exit 1
pkg="${2:-}"
loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-C}}}"
case "$loc" in
C | C.* | POSIX)
    cand=Candidate inst=Installed table="Version table"
    ;;
*)
    cand=Installationskandidat inst=Installiert table=Versionstabelle
    ;;
esac
case "$pkg" in
present)
    printf '%s:\n  %s: (none)\n  %s: 1.2.3-1\n  %s:\n     1.2.3-1 500\n' \
        "$pkg" "$inst" "$cand" "$table"
    ;;
nocand)
    printf '%s:\n  %s: (none)\n  %s: (none)\n  %s:\n' \
        "$pkg" "$inst" "$cand" "$table"
    ;;
*)
    : # unknown package: apt-cache prints nothing and exits 0
    ;;
esac
STUB_EOF
chmod +x "$STUB/apt-cache"

# Pull the function out of Global_functions.sh, which has top-level side effects
# that must not run here.
FUNCS="$WORK/funcs.sh"
body="$(awk -v fn='has_apt_candidate' '
    !on && $0 ~ "^" fn "\\(\\) \\{" { on = 1 }
    on { print }
    on && /^\}/ { exit }
' "$GLOBALS")"
if [ -z "$body" ]; then
    echo "could not extract has_apt_candidate from install-scripts/Global_functions.sh" >&2
    exit 1
fi
printf '%s\n' "$body" >"$FUNCS"

# Run a check under a given locale environment. The stub never needs the locale
# to exist, so these run on any machine.
with_stub() { # with_stub <locale> <command...>
    local loc="$1"
    shift
    (
        export PATH="$STUB:$PATH" LANG="$loc" LC_ALL="$loc"
        # shellcheck source=/dev/null
        . "$FUNCS"
        "$@"
    ) 2>/dev/null
}

detect() { # detect <package>
    if has_apt_candidate "$1"; then echo yes; else echo no; fi
}

detect_lang_only() { # detect_lang_only <package>: LC_ALL unset, only LANG set
    unset LC_ALL
    if has_apt_candidate "$1"; then echo yes; else echo no; fi
}

locale_after() { # locale_after <package>: what the caller sees after the call
    has_apt_candidate "$1" >/dev/null 2>&1 || true
    printf 'LC_ALL=%s LANG=%s' "${LC_ALL:-unset}" "${LANG:-unset}"
}

echo
echo "a real candidate counts as available"
check_eq "C locale" "$(with_stub C detect present)" "yes"
check_eq "translated locale (regression)" "$(with_stub de_DE.UTF-8 detect present)" "yes"
check_eq "translated locale via LANG only" "$(with_stub de_DE.UTF-8 detect_lang_only present)" "yes"

echo
echo "nothing installable is reported as unavailable"
check_eq "candidate (none)" "$(with_stub C detect nocand)" "no"
check_eq "candidate (none), translated locale" "$(with_stub de_DE.UTF-8 detect nocand)" "no"
check_eq "unknown package" "$(with_stub C detect unknown-pkg)" "no"
check_eq "unknown package, translated locale" "$(with_stub de_DE.UTF-8 detect unknown-pkg)" "no"

echo
echo "the locale is scoped to the call"
check_eq "caller locale untouched" \
    "$(with_stub de_DE.UTF-8 locale_after present)" \
    "LC_ALL=de_DE.UTF-8 LANG=de_DE.UTF-8"

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
