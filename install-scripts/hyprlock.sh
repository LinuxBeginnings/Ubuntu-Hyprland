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
<<<<<<< HEAD
    libmagic-dev
||||||| 814e28a
libmagic-dev
=======
	libpam0g-dev
	libgbm-dev
	libdrm-dev
    libmagic-dev
    libaudit-dev
    libsdbus-c++-dev
)

build_dep=(
    pam
>>>>>>> 25.10-development
)

#specific branch or release
lock_tag="v0.9.1"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprlock.log"
MLOG="install-$(date +%d-%H%M%S)_hyprlock2.log"

# Installation of dependencies
<<<<<<< HEAD
printf "\n%s - Installing ${SKY_BLUE}hyprlock $lock_tag${RESET} dependencies.... \n" "${NOTE}"
||||||| 814e28a
printf "\n%s - Installing hyprlock dependencies.... \n" "${NOTE}"
=======
printf "\n%s - Installing ${YELLOW}hyprlock dependencies${RESET} .... \n" "${INFO}"
>>>>>>> 25.10-development

for PKG1 in "${lock[@]}"; do
  re_install_package "$PKG1" "$LOG"
done

<<<<<<< HEAD
# Check if hyprlidle directory exists and remove it
||||||| 814e28a
# Check if hyprlidle folder exists and remove it
=======
for PKG1 in "${build_dep[@]}"; do
  build_dep "$PKG1" "$LOG"
done

# Check if hyprlock directory exists and remove it
>>>>>>> 25.10-development
if [ -d "hyprlock" ]; then
    rm -rf "hyprlock"
fi

# Clone and build hyprlock
<<<<<<< HEAD
printf "${NOTE} Compiling and Installing ${YELLOW}hyprlock $lock_tag${RESET} from source ...\n"
||||||| 814e28a
printf "${NOTE} Installing hyprlock...\n"
=======
printf "${INFO} Installing ${YELLOW}hyprlock $lock_tag${RESET} ...\n"
>>>>>>> 25.10-development
if git clone --recursive -b $lock_tag https://github.com/hyprwm/hyprlock.git; then
    cd hyprlock || exit 1
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
	cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`
    if sudo cmake --install build 2>&1 | tee -a "$MLOG" ; then
<<<<<<< HEAD
        printf "${OK} ${MAGENTA}hyprlock $lock_tag${RESET} has been successfully installed.\n" 2>&1 | tee -a "$MLOG"
||||||| 814e28a
        printf "${OK} hyprlock installed successfully.\n" 2>&1 | tee -a "$MLOG"
=======
        printf "${OK} ${YELLOW}hyprlock $lock_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
>>>>>>> 25.10-development
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}hyprlock $lock_tag${RESET}" 2>&1 | tee -a "$MLOG"
    fi
    #moving the addional logs to Install-Logs directory
    mv $MLOG ../Install-Logs/ || true 
    cd ..
else
    echo -e "${ERROR} Download failed for ${YELLOW}hyprlock $lock_tag${RESET}" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}

