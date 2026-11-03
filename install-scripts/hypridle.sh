#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# hypidle #

idle=(
    libsdbus-c++-dev
)

#specific branch or release
idle_tag="v0.1.6"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the global functions script (provides REPO_ROOT/BUILD_SRC)
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Shared version contract (HYPRIDLE_MIN_VERSION, hypridle_ok)
if ! source "$SCRIPT_DIR/Global_versions.sh"; then
  echo "Failed to source Global_versions.sh"
  exit 1
fi

# Surface failures from `cmd | tee` instead of tee's exit status
set -o pipefail

# Work in build/src to keep repo root clean
cd "$BUILD_SRC" || { echo "${ERROR} Failed to change directory to $BUILD_SRC"; exit 1; }

# Set the name of the log file to include the current date and time (under repo root)
LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hypridle.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hypridle2.log"

# ─── Skip when the packaged build already meets the minimum ──────────────────
# The Hyprland PPA and the Ubuntu repositories both ship hypridle. A source
# build installs the pinned tag into /usr/local/bin, where it would shadow a
# newer packaged binary, and its CMake needs hyprlang/hyprutils headers that
# 00-dependencies.sh purges. Only build when nothing suitable is installed.
if hypridle_ok; then
    printf "${INFO} ${YELLOW}hypridle${RESET} %s already meets the minimum %s. Skipping source build.\n" "$(bin_version hypridle)" "$HYPRIDLE_MIN_VERSION"
    printf "\n%.0s" {1..2}
    exit 0
fi

# Installation of dependencies
printf "\n%s - Installing ${YELLOW}hypridle dependencies${RESET} .... \n" "${INFO}"

for PKG1 in "${idle[@]}"; do
  if ! re_install_package "$PKG1" 2>&1 | tee -a "$LOG"; then
    echo -e "\e[1A\e[K${ERROR} - ${YELLOW}$PKG1${RESET} Package installation failed, Please check the installation logs"
    exit 1
  fi
done

# Check if hypridle directory exists and remove it
if [ -d "hypridle" ]; then
    rm -rf "hypridle"
fi

# Clone and build 
printf "${INFO} Installing ${YELLOW}hypridle $idle_tag${RESET} ...\n"
if git clone --recursive -b $idle_tag https://github.com/hyprwm/hypridle.git; then
    cd hypridle || exit 1
    # hypridle's CMake requires the hyprlang (>= 0.6.0) and hyprutils (>= 0.2.0)
    # headers. 00-dependencies.sh purges the distro -dev packages to protect
    # source-built copies, so only install them when nothing provides the
    # pkg-config modules yet.
    if ! pkg-config --exists hyprlang hyprutils 2>/dev/null; then
        printf "%s - Installing ${YELLOW}hyprlang/hyprutils${RESET} headers required by hypridle...\n" "${NOTE}"
        for PKG1 in libhyprlang-dev libhyprutils-dev; do
            install_package "$PKG1"
        done
    fi
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
	cmake --build ./build --config Release --target hypridle -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN)"
    if sudo cmake --install ./build 2>&1 | tee -a "$MLOG" ; then
        printf "${OK} ${MAGENTA}hypridle $idle_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}hypridle $idle_tag${RESET}" 2>&1 | tee -a "$MLOG"
    fi
    cd ..
else
    echo -e "${ERROR} Download failed for ${YELLOW}hypridle $idle_tag${RESET}" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
