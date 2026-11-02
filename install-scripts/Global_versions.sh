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
