#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Checks uninstall.sh backup detection and option parsing against a throwaway
# HOME. It never installs, removes or restores anything on the real system and
# needs no sudo.
#
# Usage: ./tests/uninstall-test.sh

# The uninstall prints "~/.config entry" as a label; those strings are text the
# user sees, not paths, so the tilde is intentionally literal.
# shellcheck disable=SC2088

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNINSTALL="$ROOT/uninstall.sh"

[ -f "$UNINSTALL" ] || {
    echo "cannot find uninstall.sh next to $(dirname "$ROOT")" >&2
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

# Pull one function definition out of uninstall.sh. Handles both the usual
# multi-line body and the one-line helpers (package_names, directory_names).
extract_fn() {
    awk -v fn="$1" '
        !on && $0 ~ "^" fn "\\(\\) \\{" {
            if ($0 ~ /\}[[:space:]]*$/) { print; exit }
            on = 1
        }
        on { print }
        on && /^\}/ { exit }
    ' "$UNINSTALL"
}

# ─── fixture ────────────────────────────────────────────────────────────────
FIXTURE="$WORK/home"
mkdir -p "$FIXTURE/.config/hypr" "$FIXTURE/.config/kitty" "$FIXTURE/.config/normal"

: >"$FIXTURE/.config/hypr.bak"             # *.bak
: >"$FIXTURE/.config/kitty.bak.20250101"   # *.bak.<tag>
: >"$FIXTURE/.config/waybar-backup"        # *-backup
: >"$FIXTURE/.config/swaync_backup"        # *_backup
: >"$FIXTURE/.config/rofi.old"             # *.old
: >"$FIXTURE/.config/notes.bakfoo"         # NOT a backup
: >"$FIXTURE/.config/real.conf"            # NOT a backup
: >"$FIXTURE/.zshrc-backup"
: >"$FIXTURE/.zprofile-backup"
: >"$FIXTURE/.zshrc"                       # live file, must survive dry runs

# Every check below works against the fixture, never the real home
export HOME="$FIXTURE"

FUNCS="$WORK/funcs.sh"
: >"$FUNCS"
for fn in contains_name validate_names backup_target dotfiles_backup_candidates installer_backup_list; do
    body="$(extract_fn "$fn")"
    if [ -z "$body" ]; then
        echo "could not extract $fn from uninstall.sh" >&2
        exit 1
    fi
    printf '%s\n' "$body" >>"$FUNCS"
done
# shellcheck source=/dev/null
. "$FUNCS"

echo
echo "backup_target: strip the suffix to find the live config"
check_eq "hypr.bak" "$(backup_target "$HOME/.config/hypr.bak")" "$HOME/.config/hypr"
check_eq "kitty.bak.<tag>" "$(backup_target "$HOME/.config/kitty.bak.20250101")" "$HOME/.config/kitty"
check_eq "waybar-backup" "$(backup_target "$HOME/.config/waybar-backup")" "$HOME/.config/waybar"
check_eq "swaync_backup" "$(backup_target "$HOME/.config/swaync_backup")" "$HOME/.config/swaync"
check_eq "rofi.old" "$(backup_target "$HOME/.config/rofi.old")" "$HOME/.config/rofi"
check_eq "rofi_old.old is a backup of rofi_old" \
    "$(backup_target "$HOME/.config/rofi_old.old")" "$HOME/.config/rofi_old"

echo
echo "dotfiles_backup_candidates: detect every naming style, ignore plain files"
expected="$HOME/.config/hypr.bak
$HOME/.config/kitty.bak.20250101
$HOME/.config/rofi.old
$HOME/.config/swaync_backup
$HOME/.config/waybar-backup"
check_eq "detected set" "$(dotfiles_backup_candidates | sort)" "$expected"

echo
echo "installer_backup_list: only the files the installer itself writes"
check_eq "dotfile backups" \
    "$(installer_backup_list | grep -v '^/etc/' | sort)" \
    "$HOME/.zprofile-backup
$HOME/.zshrc-backup"

echo
echo "validate_names: known names pass, typos fail"
if (validate_names "btop, kitty" package btop kitty) >/dev/null 2>&1; then
    pass "known package names accepted"
else
    fail "known package names accepted" "valid list was rejected"
fi

out="$( (validate_names "btop,nope" package btop kitty) 2>&1 )"
check_eq "typo exits 1" "$?" "1"
check_contains "typo message" "$out" "Unknown package: nope"

out="$( (validate_names "hypr,nope" "~/.config entry" hypr) 2>&1 )"
check_contains "typo in --dirs message" "$out" "Unknown ~/.config entry: nope"

# ─── end to end, always --dry-run ───────────────────────────────────────────
runit() {
    HOME="$FIXTURE" TERM=dumb bash "$UNINSTALL" "$@" 2>&1
}

echo
echo "options"
out="$(runit --help)"
check_eq "--help exits 0" "$?" "0"
check_contains "--help documents --dry-run" "$out" "--dry-run"
check_contains "--help documents --packages" "$out" "--packages"

out="$(runit --bogus)"
check_eq "unknown option exits 1" "$?" "1"
check_contains "unknown option message" "$out" "Unknown option: --bogus"

out="$(runit --yes)"
check_eq "--yes without a selection exits 1" "$?" "1"
check_contains "--yes without a selection explains why" "$out" "--yes also needs"

out="$(runit --dry-run --packages nope)"
check_eq "unknown --packages exits 1" "$?" "1"
check_contains "unknown --packages message" "$out" "Unknown package: nope"

out="$(runit --dry-run --dirs hypr,nope)"
check_eq "unknown --dirs exits 1" "$?" "1"
check_contains "unknown --dirs message" "$out" "Unknown ~/.config entry: nope"

out="$(runit --dry-run --packages btop,hyprland --dirs hypr,waybar)"
check_eq "explicit subset exits 0" "$?" "0"
check_contains "explicit subset packages" "$out" "Packages: btop hyprland"
check_contains "explicit subset directories" "$out" "Directories: hypr waybar"

out="$(runit --dry-run --dirs=kitty)"
check_eq "--dirs= form exits 0" "$?" "0"
check_contains "--dirs= form selection" "$out" "Directories: kitty"

out="$(runit --dry-run --all)"
check_eq "--dry-run --all exits 0" "$?" "0"
check_contains "--all selects packages" "$out" "Packages: btop"
check_contains "--all selects directories" "$out" "Directories: ags"
check_contains "--all lists installer backups" "$out" ".zshrc-backup"
check_contains "--all lists ~/.config backups" "$out" "hypr.bak"
case "$out" in
*"canceled"*) fail "dry run never prompts" "output says the run was canceled" ;;
*) pass "dry run never prompts" ;;
esac

echo
echo "a dry run changes nothing"
[ -d "$HOME/.config/hypr" ] && pass "~/.config/hypr kept" || fail "~/.config/hypr kept" "directory is gone"
[ -f "$HOME/.config/hypr.bak" ] && pass "~/.config/hypr.bak kept" || fail "~/.config/hypr.bak kept" "backup is gone"
[ -f "$HOME/.zshrc" ] && pass "~/.zshrc kept" || fail "~/.zshrc kept" "file is gone"
if compgen -G "$HOME/.config/*.replaced-*" >/dev/null; then
    fail "no config was replaced" "$(find "$HOME/.config" -name '*.replaced-*' -printf '%f ')"
else
    pass "no config was replaced"
fi

echo
if [ "$FAIL" -eq 0 ]; then
    printf '%s checks passed\n' "$PASS"
    exit 0
fi
printf '%s passed, %s failed\n' "$PASS" "$FAIL"
exit 1
