#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Thunar-default #


## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Repo root as cwd + absolute, collision-free log path
init_script "thunar-default"

printf "${INFO} Setting ${SKY_BLUE}Thunar${RESET} as default file manager...\n"  
 
xdg-mime default thunar.desktop inode/directory
xdg-mime default thunar.desktop application/x-wayland-gnome-saved-search
echo "${OK} ${MAGENTA}Thunar${RESET} is now set as the default file manager." | tee -a "$LOG"

printf "\n%.0s" {1..2}
