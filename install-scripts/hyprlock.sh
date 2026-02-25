#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# hyprlock #

lock=(
	libpam0g-dev
	libgbm-dev
	libdrm-dev
    libmagic-dev
    libaudit-dev
    libsdbus-c++-dev
)

build_dep=(
    pam
)

#specific branch or release
lock_tag="v0.9.1"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the global functions script (provides REPO_ROOT/BUILD_SRC)
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Work in build/src to keep repo root clean
cd "$BUILD_SRC" || { echo "${ERROR} Failed to change directory to $BUILD_SRC"; exit 1; }

# Set the name of the log file to include the current date and time (under repo root)
LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hyprlock.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hyprlock2.log"

# Installation of dependencies
printf "\n%s - Installing ${YELLOW}hyprlock dependencies${RESET} .... \n" "${INFO}"

for PKG1 in "${lock[@]}"; do
  re_install_package "$PKG1" "$LOG"
done

for PKG1 in "${build_dep[@]}"; do
  build_dep "$PKG1" "$LOG"
done

# Check if hyprlock directory exists and remove it
if [ -d "hyprlock" ]; then
    rm -rf "hyprlock"
fi

# Clone and build hyprlock
printf "${INFO} Installing ${YELLOW}hyprlock $lock_tag${RESET} ...\n"
if git clone --recursive -b $lock_tag https://github.com/hyprwm/hyprlock.git; then
    cd hyprlock || exit 1
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
	cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`
    if sudo cmake --install build 2>&1 | tee -a "$MLOG" ; then
        printf "${OK} ${YELLOW}hyprlock $lock_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}hyprlock $lock_tag${RESET}" 2>&1 | tee -a "$MLOG"
    fi
    cd ..
else
    echo -e "${ERROR} Download failed for ${YELLOW}hyprlock $lock_tag${RESET}" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}

