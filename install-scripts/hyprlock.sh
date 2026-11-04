#!/usr/bin/env bash
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

# Shared version contract (HYPRLOCK_MIN_VERSION, hyprlock_ok)
if ! source "$SCRIPT_DIR/Global_versions.sh"; then
  echo "Failed to source Global_versions.sh"
  exit 1
fi

# Work in build/src to keep repo root clean
cd "$BUILD_SRC" || { echo "${ERROR} Failed to change directory to $BUILD_SRC"; exit 1; }

# Set the name of the log file to include the current date and time (under repo root)
LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hyprlock.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hyprlock2.log"

# ─── Skip when the packaged build already meets the minimum ──────────────────
# The Hyprland PPA and the Ubuntu repositories both ship hyprlock. A source
# build installs the pinned tag into /usr/local/bin, where it would shadow a
# newer packaged binary, and its CMake needs hyprlang/hyprutils/hyprgraphics
# headers that 00-dependencies.sh purges. Only build when nothing suitable is
# installed.
if hyprlock_ok; then
    printf "${INFO} ${YELLOW}hyprlock${RESET} %s already meets the minimum %s. Skipping source build.\n" "$(bin_version hyprlock)" "$HYPRLOCK_MIN_VERSION"
    printf "\n%.0s" {1..2}
    exit 0
fi

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
    # hyprlock's CMake requires the hyprlang (>= 0.6.0), hyprutils (>= 0.8.0) and
    # hyprgraphics headers. 00-dependencies.sh purges the distro -dev packages to
    # protect source-built copies, so only install them when nothing provides the
    # pkg-config modules yet.
    if ! pkg-config --exists hyprlang hyprutils hyprgraphics 2>/dev/null; then
        printf "%s - Installing ${YELLOW}hyprlang/hyprutils/hyprgraphics${RESET} headers required by hyprlock...\n" "${NOTE}"
        for PKG1 in libhyprlang-dev libhyprutils-dev libhyprgraphics-dev; do
            install_package "$PKG1"
        done
    fi
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
	cmake --build ./build --config Release --target hyprlock "-j$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
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

