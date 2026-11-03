#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Nvidia - Check Readme for more details for the drivers #
# UBUNTU USERS, FOLLOW README!

nvidia_pkg=(
  libva-wayland2
  libnvidia-egl-wayland1
  nvidia-vaapi-driver
)

# for ubuntu-nvidia owners! just delete #
if command -v ubuntu-drivers >/dev/null 2>&1; then
  sudo ubuntu-drivers install
else
  echo "WARN: ubuntu-drivers not found - install the NVIDIA driver manually (see README)."
fi

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Surface failures from `cmd | tee` instead of tee's exit status
set -o pipefail

# Repo root as cwd + absolute, collision-free log path
init_script "nvidia"
MLOG="install-$(date +%d-%H%M%S)_nvidia2.log"


# Update the package list
sudo apt update

# Function to add a single line to a configuration file if not present.
# Lines are compared literally (-F), so re-running the installer is idempotent:
# the previous `grep "$value"` test could never match the multi-line block and
# appended a duplicate copy on every run.
add_line_if_missing() {
    local config_file="$1"
    local value="$2"

    if sudo grep -qxF "$value" "$config_file" 2>/dev/null; then
        echo "$value is already present in $config_file."
        return 0
    fi
    echo "Adding $value to $config_file"
    printf '%s\n' "$value" | sudo tee -a "$config_file" >/dev/null
}

# Install additional Nvidia packages
printf "${YELLOW} Installing ${SKY_BLUE}Nvidia packages${RESET} ...\n"
  for NVIDIA in "${nvidia_pkg[@]}"; do
    install_package "$NVIDIA" "$LOG"
  done

# adding additional nvidia-stuff
printf "${YELLOW} adding ${SKY_BLUE}nvidia-stuff${RESET} to /etc/default/grub..."

  # Additional options to add to GRUB_CMDLINE_LINUX
  additional_options="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 rcutree.rcu_idle_gp_delay=1"

  # Check if additional options are already present in GRUB_CMDLINE_LINUX
  if grep -q "GRUB_CMDLINE_LINUX.*$additional_options" /etc/default/grub; then
    echo "GRUB_CMDLINE_LINUX already contains the additional options"
  else
    # Append the additional options to GRUB_CMDLINE_LINUX
    sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$additional_options /" /etc/default/grub
    echo "Added the additional options to GRUB_CMDLINE_LINUX"
  fi

  # Update GRUB configuration
  sudo update-grub 2>&1 | tee -a "$LOG"
    
  # Define the configuration file and the lines to add
    config_file="/etc/modprobe.d/nvidia.conf"
    modprobe_lines=(
        "options nvidia-drm modeset=1 fbdev=1"
        "options nvidia NVreg_PreserveVideoMemoryAllocations=1"
    )

    # Check if the config file exists
    if [ ! -e "$config_file" ]; then
        echo "Creating $config_file"
        sudo touch "$config_file"
    fi

    for line in "${modprobe_lines[@]}"; do
        add_line_if_missing "$config_file" "$line" 2>&1 | tee -a "$LOG"
    done

   # Add NVIDIA modules to initramfs configuration
   modules_file="/etc/initramfs-tools/modules"

   if [ -e "$modules_file" ]; then
    for module in nvidia nvidia_modeset nvidia_uvm nvidia_drm; do
        add_line_if_missing "$modules_file" "$module" 2>&1 | tee -a "$LOG"
    done
    sudo update-initramfs -u 2>&1 | tee -a "$LOG"
   else
    echo "Modules file ($modules_file) not found." 2>&1 | tee -a "$LOG"
   fi

printf "\n%.0s" {1..2}
