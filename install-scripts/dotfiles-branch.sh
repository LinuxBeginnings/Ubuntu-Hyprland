#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Hyprland-Dots to download from main #

#specific branch or release

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

# Runs copy.sh and proves it installed something. Without this the script always
# exited 0, so install.sh reported the dots as installed even when the copy
# failed or wrote nothing, and the final check had no idea.
install_dots() {
  if ! chmod +x copy.sh; then
    echo "${ERROR} Could not make copy.sh executable in $PWD" >&2
    return 1
  fi
  if ! ./copy.sh; then
    echo "${ERROR} copy.sh failed in $PWD" >&2
    return 1
  fi
  if [ ! -d "$HOME/.config/hypr" ]; then
    echo "${ERROR} copy.sh finished but $HOME/.config/hypr is missing" >&2
    return 1
  fi
  return 0
}

printf "${NOTE} Cloning and Installing ${SKY_BLUE}KooL's Hyprland Dots for Ubuntu${RESET}....\n"

# Check if Hyprland-Dots exists
if [ -d Hyprland-Dots-Ubuntu ]; then
  cd Hyprland-Dots-Ubuntu || exit 1
  git stash || true
  if ! git pull; then
    echo "${WARN} Could not update the existing Hyprland-Dots checkout; using it as-is." >&2
  fi
  install_dots || exit 1
else
  if git clone --depth=1 https://github.com/LinuxBeginnings/Hyprland-Dots Hyprland-Dots-Ubuntu; then
    cd Hyprland-Dots-Ubuntu || exit 1
    install_dots || exit 1
  else
    echo -e "$ERROR Can't download ${YELLOW}KooL's Hyprland-Dots-Ubuntu${RESET}" >&2
    exit 1
  fi
fi

printf "\n%.0s" {1..2}
