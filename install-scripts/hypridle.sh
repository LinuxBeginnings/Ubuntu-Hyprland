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

# Work in build/src to keep repo root clean
cd "$BUILD_SRC" || { echo "${ERROR} Failed to change directory to $BUILD_SRC"; exit 1; }

# Set the name of the log file to include the current date and time (under repo root)
LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hypridle.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hypridle2.log"

# Skip source build if hypridle is already installed (e.g. from PPA or apt repo)
if [ "${1:-}" != "--force" ] && [ "${1:-}" != "--reinstall" ]; then
  if command -v hypridle >/dev/null 2>&1 || [ -x /usr/local/bin/hypridle ] || is_pkg_installed hypridle; then
    echo -e "${INFO} ${MAGENTA}hypridle${RESET} is already installed ($(command -v hypridle 2>/dev/null || echo 'dpkg/local')). Skipping source build." | tee -a "$LOG"
    exit 0
  fi
fi

# Installation of dependencies
printf "\n%s - Installing ${YELLOW}hypridle dependencies${RESET} .... \n" "${INFO}"

for PKG1 in "${idle[@]}"; do
  re_install_package "$PKG1" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
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
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_PREFIX_PATH=/usr/local -S . -B ./build
	cmake --build ./build --config Release --target hypridle -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
    if sudo cmake --install ./build 2>&1 | tee -a "$MLOG" ; then
        sudo ldconfig 2>/dev/null || true
        printf "${OK} ${MAGENTA}hypridle $idle_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}hypridle $idle_tag${RESET}" 2>&1 | tee -a "$MLOG"
    fi
    cd ..
else
    echo -e "${ERROR} Download failed for ${YELLOW}hypridle $idle_tag${RESET}" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
