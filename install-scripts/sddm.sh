#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# SDDM with optional SDDM theme #

# installing with NO-recommends
sddm1=(
  sddm
)

sddm2=(
  libqt6svg6
  qt6-declarative-dev
  qt6-svg-dev
  qt6-virtualkeyboard-plugin
  libqt6multimedia6
  qml6-module-qtquick-controls
  qml6-module-qtquick-effects
)

# login managers to attempt to disable
login=(
  lightdm 
  gdm3 
  gdm 
  lxdm 
  lxdm-gtk3
)

# login managers to attempt to disable
login=(
  lightdm 
  gdm3 
  gdm 
  lxdm 
  lxdm-gtk3
)

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm.log"


# Install SDDM (no-recommends)
printf "\n%s - Installing ${SKY_BLUE}SDDM and dependencies${RESET} .... \n" "${NOTE}"
for PKG1 in "${sddm1[@]}" ; do
<<<<<<< HEAD
  sudo apt install --no-install-recommends -y "$PKG1" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    echo -e "\e[1A\e[K${ERROR} - $PKG1 Package installation failed, Please check the installation logs"
    exit 1
  fi
||||||| 814e28a
  sudo apt-get install --no-install-recommends -y "$PKG1" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    echo -e "\e[1A\e[K${ERROR} - $PKG1 Package installation failed, Please check the installation logs"
    exit 1
  fi
=======
  sudo apt install --no-install-recommends -y "$PKG1" | tee -a "$LOG"
>>>>>>> 25.10-development
done

# Installation of additional sddm stuff
for PKG2 in "${sddm2[@]}"; do
  install_package "$PKG2"  "$LOG"
done

<<<<<<< HEAD
# Check if other login managers are installed and disable their service before enabling SDDM
for login_manager in "${login[@]}"; do
  if sudo apt list --installed "$login_manager" > /dev/null; then
||||||| 814e28a
# Check if other login managers are installed and disabling their service before enabling sddm
for login_manager in lightdm gdm lxdm lxdm-gtk3; do
  if sudo apt-get list installed "$login_manager" &>> /dev/null; then
=======
# Check if other login managers are installed and disable their service before enabling SDDM
for login_manager in "${login[@]}"; do
  if dpkg -l | grep -q "^ii  $login_manager"; then
>>>>>>> 25.10-development
    echo "Disabling $login_manager..."
<<<<<<< HEAD
    sudo systemctl disable "$login_manager.service" >> "$LOG" 2>&1
    echo "$login_manager disabled."
||||||| 814e28a
    sudo systemctl disable "$login_manager" 2>&1 | tee -a "$LOG"
=======
    sudo systemctl disable "$login_manager.service" >> "$LOG" 2>&1 || echo "Failed to disable $login_manager" >> "$LOG"
    echo "$login_manager disabled."
>>>>>>> 25.10-development
  fi
done

<<<<<<< HEAD
# Double check with systemctl
for manager in "${login[@]}"; do
  if systemctl is-active --quiet "$manager" > /dev/null 2>&1; then
    echo "$manager is active, disabling it..." >> "$LOG" 2>&1
    sudo systemctl disable "$manager" --now >> "$LOG" 2>&1
  fi
done
||||||| 814e28a
printf " Activating sddm service........\n"
sudo systemctl enable sddm
=======
# Double check with systemctl
for manager in "${login[@]}"; do
  if systemctl is-active --quiet "$manager.service" > /dev/null 2>&1; then
    echo "$manager.service is active, disabling it..." >> "$LOG" 2>&1
    sudo systemctl disable "$manager.service" --now >> "$LOG" 2>&1 || echo "Failed to disable $manager.service" >> "$LOG"
  else
    echo "$manager.service is not active" >> "$LOG" 2>&1
  fi
done
>>>>>>> 25.10-development

<<<<<<< HEAD
printf "\n%.0s" {1..1}
printf "${INFO} Activating sddm service........\n"
sudo systemctl enable sddm
||||||| 814e28a
# Set up SDDM
echo -e "${NOTE} Setting up the login screen."
sddm_conf_dir=/etc/sddm.conf.d
[ ! -d "$sddm_conf_dir" ] && { printf "$CAT - $sddm_conf_dir not found, creating...\n"; sudo mkdir -p "$sddm_conf_dir" 2>&1 | tee -a "$LOG"; }
=======
printf "\n%.0s" {1..1}
printf "${INFO} Activating sddm service........\n"
sudo systemctl set-default graphical.target 2>&1 | tee -a "$LOG"
sudo systemctl enable sddm.service 2>&1 | tee -a "$LOG"
>>>>>>> 25.10-development

wayland_sessions_dir=/usr/share/wayland-sessions
[ ! -d "$wayland_sessions_dir" ] && { printf "$CAT - $wayland_sessions_dir not found, creating...\n"; sudo mkdir -p "$wayland_sessions_dir" 2>&1 | tee -a "$LOG"; }
<<<<<<< HEAD
sudo cp assets/hyprland.desktop "$wayland_sessions_dir/" 2>&1 | tee -a "$LOG"
||||||| 814e28a
sudo cp assets/hyprland.desktop "$wayland_sessions_dir/" 2>&1 | tee -a "$LOG"
    
# SDDM-themes
valid_input=false
while [ "$valid_input" != true ]; do
  read -n 1 -r -p "${CAT} OPTIONAL - Would you like to install SDDM themes? (y/n)" install_sddm_theme
  if [[ $install_sddm_theme =~ ^[Yy]$ ]]; then
    printf "\n%s - Installing Simple SDDM Theme\n" "${NOTE}"
=======
>>>>>>> 25.10-development

printf "\n%.0s" {1..2}