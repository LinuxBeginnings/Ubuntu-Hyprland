#!/bin/bash
<<<<<<< HEAD
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# hyprlang - hyprland and xdg-desktop-portal- dependencies #
||||||| 814e28a
# 💫 https://github.com/JaKooLit 💫 #
# hyprlang - hyprland and xdg-desktop-portal- dependencies #
=======
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# hyplang #

>>>>>>> 25.10-development

#specific branch or release
<<<<<<< HEAD
lang_tag="v0.5.2"
||||||| 814e28a
lang_tag="v0.5.1"
=======
lang_tag="v0.6.4"
>>>>>>> 25.10-development

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprlang.log"
MLOG="install-$(date +%d-%H%M%S)_hyprlang2.log"

# Prefer locally built hyprutils in /usr/local
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export CMAKE_PREFIX_PATH="/usr/local:${CMAKE_PREFIX_PATH:-}"

<<<<<<< HEAD
# Check if hyprlang directory exists and remove it
||||||| 814e28a
# Check if hyprlang folder exists and remove it
=======
# Installation of dependencies
printf "\n%s - Installing ${YELLOW}hyprlang dependencies${RESET} .... \n" "${INFO}"

# Check if hyprlang directory exists and remove it
>>>>>>> 25.10-development
if [ -d "hyprlang" ]; then
    rm -rf "hyprlang"
fi

<<<<<<< HEAD
# Clone and build hyprlang
printf "${NOTE} Compiling and Installing ${YELLOW}hyprlang $lang_tag${RESET} from source ...\n"
||||||| 814e28a
# Clone and build hyprlang
printf "${NOTE} Installing hyprlang...\n"
=======
# Clone and build 
printf "${INFO} Installing ${YELLOW}hyprlang $lang_tag${RESET} ...\n"
>>>>>>> 25.10-development
if git clone --recursive -b $lang_tag https://github.com/hyprwm/hyprlang.git; then
    cd hyprlang || exit 1
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target hyprlang -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`
    if sudo cmake --install ./build 2>&1 | tee -a "$MLOG" ; then
<<<<<<< HEAD
        printf "${OK} ${YELLOW}hyprlang $lang_tag${MAGENTA} has been successfully installed.\n" 2>&1 | tee -a "$MLOG"
||||||| 814e28a
        printf "${OK} hyprlang installed successfully.\n" 2>&1 | tee -a "$MLOG"
=======
        printf "${OK} ${MAGENTA}hyprlang $lang_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
>>>>>>> 25.10-development
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}hyprlang $lang_tag${RESET}" 2>&1 | tee -a "$MLOG"
    fi
    #moving the addional logs to Install-Logs directory
    mv $MLOG ../Install-Logs/ || true 
    cd ..
else
    echo -e "${ERROR} Download failed for ${YELLOW}hyprlang $lang_tag${RESET}" 2>&1 | tee -a "$LOG"
fi

<<<<<<< HEAD
printf "\n%.0s" {1..2}
||||||| 814e28a

clear

=======
printf "\n%.0s" {1..2}
>>>>>>> 25.10-development
