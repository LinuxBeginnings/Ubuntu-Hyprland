#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Hyprland-Dots Packages #
# The package lists live in install-scripts/packages.sh so that the installer and
# 03-Final-Check.sh verify the same set. Add packages to Extra here, or to that
# manifest when they must also be verified.

# add packages wanted here
Extra=(

)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi

# Shared package manifest (hypr_required, hypr_optional, hypr_force, hypr_uninstall)
if ! source "$SCRIPT_DIR/packages.sh"; then
    echo "Failed to source packages.sh"
    exit 1
fi

# Surface failures from `cmd | tee` instead of tee's exit status
set -o pipefail

# Repo root as cwd + absolute, collision-free log path
init_script "hypr-pkgs"
# Detect installed rofi version (from PATH, including /usr/local builds)
get_rofi_version() {
    if command -v rofi >/dev/null 2>&1; then
        rofi -version 2>/dev/null | awk 'NR==1 {print $2}'
    fi
}

rofi_installed_ver="$(get_rofi_version || true)"
rofi_ok=0
if [ -n "$rofi_installed_ver" ]; then
    if dpkg --compare-versions "$rofi_installed_ver" ge "2.0.0"; then
        rofi_ok=1
        echo "${INFO} Detected rofi ${YELLOW}$rofi_installed_ver${RESET} (>= 2.0.0). Skipping rofi uninstall." | tee -a "$LOG"
    fi
fi

# conflicting packages removal
overall_failed=0
printf "\n%s - ${SKY_BLUE}Removing some packages${RESET} as it conflicts with KooL's Hyprland Dots \n" "${NOTE}"
for PKG in "${hypr_uninstall[@]}"; do
    if [ "$rofi_ok" -eq 1 ] && [ "$PKG" = "rofi" ]; then
        echo "${INFO} Skipping uninstall of ${YELLOW}$PKG${RESET} (rofi >= 2.0.0 detected)." | tee -a "$LOG"
        continue
    fi
    if ! uninstall_package "$PKG" 2>&1 | tee -a "$LOG"; then
        overall_failed=1
    fi
done

if [ $overall_failed -ne 0 ]; then
    echo -e "${ERROR} Some packages failed to uninstall. Please check the log."
fi

printf "\n%.0s" {1..1}

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}KooL's hyprland necessary packages${RESET} .... \n" "${NOTE}"

# Keep going after a single failure so the rest of the set still gets installed;
# install_package records the failure and the step fails at the end.
for PKG1 in "${hypr_required[@]}" "${hypr_optional[@]}" "${Extra[@]}"; do
    install_package "$PKG1" "$LOG" || true
done

printf "\n%.0s" {1..1}

for PKG2 in "${hypr_force[@]}"; do
    re_install_package "$PKG2" "$LOG" || true
done

printf "\n%.0s" {1..1}

# Install nwg-dock-hyprland via dedicated repo script when missing (no native Ubuntu package)
if ! command -v nwg-dock-hyprland >/dev/null 2>&1; then
    NWG_DOCK_INSTALLER="$REPO_ROOT/install-scripts/nwg-dock-hyprland.sh"
    echo "${INFO} ${YELLOW}nwg-dock-hyprland${RESET} not found. Running dedicated nwg-dock-hyprland installer..." | tee -a "$LOG"
    if [ -x "$NWG_DOCK_INSTALLER" ]; then
        "$NWG_DOCK_INSTALLER"
    elif [ -f "$NWG_DOCK_INSTALLER" ]; then
        bash "$NWG_DOCK_INSTALLER"
    else
        echo "${ERROR} Could not find ${YELLOW}nwg-dock-hyprland.sh${RESET} at $NWG_DOCK_INSTALLER" | tee -a "$LOG"
        exit 1
    fi
else
    echo "${INFO} ${YELLOW}nwg-dock-hyprland${RESET} is already installed. Skipping dedicated installer." | tee -a "$LOG"
fi

printf "\n%.0s" {1..1}

# Install up-to-date Rust. A failed download is not fatal: wallust.sh and
# swww.sh install the toolchain themselves when cargo is missing.
echo "${INFO} Installing most ${YELLOW}up to date Rust compiler${RESET} ..."
if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tee -a "$LOG"; then
    echo "${WARN} Rust toolchain download failed. wallust.sh/swww.sh will retry it." | tee -a "$LOG"
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env" 2>/dev/null || true

## making brightnessctl work
sudo chmod +s "$(command -v brightnessctl)" 2>&1 | tee -a "$LOG" || true

printf "\n%.0s" {1..2}

# Fail the step (and stop install.sh) when anything could not be installed
if ! report_install_failures; then
    echo -e "${ERROR} Check ${YELLOW}$LOG${RESET} and Install-Logs/failed-packages.txt" | tee -a "$LOG"
    exit 1
fi
