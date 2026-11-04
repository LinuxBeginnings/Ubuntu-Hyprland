#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# This script is cleaning up previous manual installation files / directories

# 22 Aug 2024
# Files to be removed from /usr/local/bin

TARGET_DIR="/usr/local/bin"

# Define packages to manually remove (was manually installed previously)
# NOTE: waybar is deliberately not listed. It is managed by waybar.sh, which
# rebuilds only when the installed build is below WAYBAR_MIN_VERSION; removing
# the binary here would force a full source build on every install run.
PACKAGES=(
  hyprctl
  hyprpm
  hyprland
  Hyprland
  cliphist
  pypr
  swappy
  magick
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Surface failures from `cmd | tee` instead of tee's exit status
set -o pipefail

# Repo root as cwd + absolute, collision-free log path
init_script "pre-clean-up"

# Loop through the list of packages
for PKG_NAME in "${PACKAGES[@]}"; do
  # Construct the full path to the file
  FILE_PATH="$TARGET_DIR/$PKG_NAME"

  # Check if the file exists
  if [[ -f "$FILE_PATH" ]]; then
    # Delete the file
    sudo rm "$FILE_PATH"
    echo "Deleted: $FILE_PATH" 2>&1 | tee -a "$LOG"
  else
    echo "File not found: $FILE_PATH" 2>&1 | tee -a "$LOG"
  fi
done

clear