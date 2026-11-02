#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Shared minimum-version contract for tools the dotfiles depend on.
# Leaf file: prints nothing and has no side effects, so it is safe to source
# from install scripts, the final check, and update-deps.sh alike.

# Minimum Quickshell release. Quickshell is required on Ubuntu 26.04+, where the
# dotfiles ship several Quickshell apps, so bump the requirement here only.
QS_MIN_VERSION="0.3.0"

# Path to the quickshell binary (PATH first, then /usr/local source builds).
quickshell_bin() {
    if command -v quickshell >/dev/null 2>&1; then
        command -v quickshell
    elif [ -x /usr/local/bin/quickshell ]; then
        echo /usr/local/bin/quickshell
    fi
}

# Succeeds when a quickshell binary is present, runnable or not.
quickshell_present() {
    [ -n "$(quickshell_bin)" ]
}

# Version reported by the binary; empty when it is absent or cannot run
# (e.g. built against a Qt that has since been upgraded).
quickshell_version() {
    local bin
    bin="$(quickshell_bin || true)"
    [ -n "$bin" ] || return 0
    timeout 10 "$bin" -V 2>&1 | grep -oE '[0-9]+(\.[0-9]+){1,2}' | head -n1 || true
}

# version_ge A B -> succeeds when A >= B
version_ge() {
    if command -v dpkg >/dev/null 2>&1; then
        dpkg --compare-versions "$1" ge "$2"
    else
        [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
    fi
}

# Succeeds only when quickshell is installed and meets QS_MIN_VERSION.
quickshell_ok() {
    local ver
    ver="$(quickshell_version)"
    [ -n "$ver" ] || return 1
    version_ge "$ver" "$QS_MIN_VERSION"
}

# ─── Waybar ──────────────────────────────────────────────────────────────────
# Minimum Waybar build the dotfiles support. The Hyprland Lua workflow needs a
# master build (a release tag is not enough), so this is the build verified on
# Ubuntu 26.04 on 2026-11-02. Bump the requirement here only.
WAYBAR_MIN_VERSION="0.15.0-1100-gf6f73c81"

# ─── hyprlock / hypridle ─────────────────────────────────────────────────────
# Tags installed by the hyprlock.sh / hypridle.sh source builds. A packaged
# build at or above the tag is good enough, so those scripts skip the build.
HYPRIDLE_MIN_VERSION="0.1.6"
HYPRLOCK_MIN_VERSION="0.9.1"

# Path to a binary (PATH first, then /usr/local source builds).
bin_path() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
    elif [ -x "/usr/local/bin/$name" ]; then
        echo "/usr/local/bin/$name"
    fi
}

# Version of NAME: what the binary reports, else the packaged version. Empty
# when the tool is absent or cannot run.
bin_version() {
    local bin ver
    bin="$(bin_path "$1" || true)"
    if [ -n "$bin" ]; then
        ver="$(timeout 10 "$bin" --version 2>&1 | grep -oE '[0-9]+(\.[0-9]+){1,2}' | head -n1 || true)"
        if [ -n "$ver" ]; then
            printf '%s\n' "$ver"
            return 0
        fi
    fi
    dpkg-query -W -f='${Version}' "$1" 2>/dev/null |
        grep -oE '[0-9]+(\.[0-9]+){1,2}' | head -n1 || true
}

# Succeeds when NAME is installed at or above MIN_VERSION.
bin_at_least() {
    local ver
    ver="$(bin_version "$1")"
    [ -n "$ver" ] || return 1
    version_ge "$ver" "$2"
}

# Waybar's version, keeping the git-describe suffix so master builds can be
# ordered (0.15.0-1100-gabcdef is newer than 0.15.0-800-gabcdef).
waybar_version() {
    local bin line
    bin="$(bin_path waybar || true)"
    [ -n "$bin" ] || return 0
    line="$(timeout 10 "$bin" --version 2>&1 | grep -iE 'waybar v' || true)"
    printf '%s\n' "$line" |
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+-g[0-9a-f]+)?' | head -n1 || true
}

# Succeeds only when waybar is installed, runnable and at least WAYBAR_MIN_VERSION.
waybar_ok() {
    local ver
    ver="$(waybar_version)"
    [ -n "$ver" ] || return 1
    version_ge "$ver" "$WAYBAR_MIN_VERSION"
}

# Succeeds when the installed hypridle / hyprlock meets the pinned tag.
hypridle_ok() { bin_at_least hypridle "$HYPRIDLE_MIN_VERSION"; }
hyprlock_ok() { bin_at_least hyprlock "$HYPRLOCK_MIN_VERSION"; }
