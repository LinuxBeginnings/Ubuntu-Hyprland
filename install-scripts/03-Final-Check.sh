#!/usr/bin/env bash
# Arrays come from packages.sh, sourced below via "$SCRIPT_DIR"; shellcheck cannot
# follow that path, so their references look unassigned here.
# shellcheck disable=SC2154
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Final checking if packages are installed
# NOTE: These package checks are only the essentials

# Binaries expected to be available (installed via PPA into /usr/bin)
local_pkgs_installed=(
    hypridle
    hyprlock
    rofi
    wallust
    awww
    nwg-dock-hyprland
    hyprland-dialog
    luac
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
    echo "${ERROR} Failed to change directory to $PARENT_DIR"
    exit 1
}

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi
# Shared version contract (QS_MIN_VERSION, quickshell_* helpers)
if ! source "$SCRIPT_DIR/Global_versions.sh"; then
    echo "Failed to source Global_versions.sh"
    exit 1
fi
# Shared package manifest: every hypr_required entry is installed by
# 01-hypr-pkgs.sh, plus the packages installed by dedicated scripts.
if ! source "$SCRIPT_DIR/packages.sh"; then
    echo "Failed to source packages.sh"
    exit 1
fi
packages=("${hypr_required[@]}" "${final_check_extra[@]}")

# Surface failures from `cmd | tee` instead of tee's exit status
set -o pipefail

# Set the name of the log file to include the current date and time
LOG="Install-Logs/00_CHECK-$(date +%d-%H%M%S)_installed.log"

printf "\n%s - Final Check if Essential packages were installed \n" "${NOTE}"
# Initialize an empty array to hold missing packages
missing=()
local_missing=()

# Function to check if a package is installed using dpkg
is_installed_dpkg() {
    # Special-case Hyprland: consider it installed if present on PATH or in /usr/local/bin
    if [ "$1" = "hyprland" ]; then
        if command -v Hyprland >/dev/null 2>&1 ||
            command -v hyprland >/dev/null 2>&1 ||
            [ -x "/usr/local/bin/Hyprland" ] ||
            [ -x "/usr/local/bin/hyprland" ]; then
            return 0
        fi
    fi
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"
}

# Loop through each package
for pkg in "${packages[@]}"; do
    # Check if the package is installed via dpkg
    if ! is_installed_dpkg "$pkg"; then
        missing+=("$pkg")
    fi
done

# Waybar must be a source build at or above WAYBAR_MIN_VERSION: the Hyprland Lua
# workflow needs a master build and the APT package (in /usr/bin) is too old.
WAYBAR_VERSION="$(waybar_version)"
if ! waybar_ok; then
    local_missing+=("waybar (< $WAYBAR_MIN_VERSION required, found ${WAYBAR_VERSION:-unknown})")
fi

for pkg1 in "${local_pkgs_installed[@]}"; do
    if ! command -v "$pkg1" >/dev/null 2>&1; then
        local_missing+=("$pkg1")
    fi
done

# Quickshell is required on Ubuntu 26.04+ (the dotfiles ship several Quickshell
# apps), and must be new enough when present.
QS_VERSION="$(quickshell_version)"
if ! quickshell_present; then
    local_missing+=("quickshell (required)")
elif quickshell_ok; then
    # Not logged: update-deps.sh treats every line here as a missing package.
    echo "${OK} Quickshell ${QS_VERSION} meets the minimum ${QS_MIN_VERSION}."
else
    local_missing+=("quickshell (< $QS_MIN_VERSION required, found ${QS_VERSION:-unknown})")
fi

# Which path provided Hyprland: the PPA and the Ubuntu repositories both work,
# but a user chasing a version or feature difference needs to know which one
# ran. Printed only: update-deps.sh reads this log as a list of missing
# packages, so it must stay a plain package list.
hypr_src="$(hyprland_source_field 1)"
hypr_reason="$(hyprland_source_field 2)"
case "$hypr_src" in
ppa)
    echo "${INFO} Hyprland came from the community ${MAGENTA}PPA${RESET}."
    ;;
ubuntu)
    echo "${INFO} Hyprland came from the ${MAGENTA}Ubuntu repositories${RESET}."
    if [ -n "$hypr_reason" ]; then
        echo "${WARN} The community PPA path was not used: ${hypr_reason}."
    fi
    ;;
ppa-failed)
    echo "${WARN} The community PPA path did not provide Hyprland: ${hypr_reason}."
    ;;
esac

# Optional components that did not install
# install.sh records them in Install-Logs/optional-failures.txt. Printed only:
# update-deps.sh reads this log as a list of missing packages, so these names
# must not be appended to it.
optional_failures="$REPO_ROOT/Install-Logs/optional-failures.txt"
if [ -s "$optional_failures" ]; then
    echo "${WARN} These optional components did not install:"
    while IFS= read -r component; do
        [ -n "$component" ] && echo "  - $component"
    done <"$optional_failures"
fi

# Log missing packages
if [ ${#missing[@]} -eq 0 ] && [ ${#local_missing[@]} -eq 0 ]; then
    echo "${OK} GREAT! All ${YELLOW}essential packages${RESET} have been successfully installed." | tee -a "$LOG"
else
    if [ ${#missing[@]} -ne 0 ]; then
        echo "${WARN} The following packages are not installed and will be logged:"
        for pkg in "${missing[@]}"; do
            echo "$pkg"
            echo "$pkg" >>"$LOG" # Log the missing package to the file
        done
    fi

    if [ ${#local_missing[@]} -ne 0 ]; then
        echo "${WARN} The following binaries are missing from PATH and will be logged:"
        for pkg1 in "${local_missing[@]}"; do
            # Entries carrying their own detail (e.g. a version mismatch) are
            # printed as-is; plain names get the PATH hint.
            case "$pkg1" in
            *"("*) echo "$pkg1" ;;
            *) echo "$pkg1 (not found in PATH)" ;;
            esac
            echo "$pkg1" >>"$LOG" # Log the missing local package to the file
        done
    fi

    # Add a timestamp when the missing packages were logged
    echo "${NOTE} Missing packages logged at $(date)" >>"$LOG"

    # Fail the check so update-deps.sh and CI can gate on it. install.sh ignores
    # this status on purpose: the final check is the last thing it runs and the
    # summary above is what the user reads.
    exit 1
fi
