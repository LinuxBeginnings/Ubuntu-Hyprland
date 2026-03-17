#!/bin/bash
<<<<<<< HEAD
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# XDG-Desktop-Portals #
||||||| 814e28a
# 💫 https://github.com/JaKooLit 💫 #
# XDG-Desktop-Portals #
=======
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# XDG-Desktop-Portal-Hyprland (build from source)
>>>>>>> 25.10-development

<<<<<<< HEAD
xdg=(
    libpipewire-0.3-dev
    libspa-0.2-dev
    libdrm-dev
    libgbm-dev
    wayland-protocols  
    xdg-desktop-portal-gtk
||||||| 814e28a
xdg=(
xdg-desktop-portal-gtk
=======
xdg_deps=(
  libdrm-dev
  libpipewire-0.3-dev
  libspa-0.2-dev
  libsdbus-c++-dev
  libwayland-client0
  wayland-protocols
  xdg-desktop-portal-gtk
>>>>>>> 25.10-development
)

<<<<<<< HEAD
#specific branch or release
xdph_tag="v1.3.2"

||||||| 814e28a
=======
#specific branch or release
tag="v1.3.10"

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

LOG="Install-Logs/install-$(date +%d-%H%M%S)_xdph.log"
MLOG="install-$(date +%d-%H%M%S)_xdph2.log"

<<<<<<< HEAD
printf "${NOTE} Installing ${SKY_BLUE}xdg-desktop-portal-hyprland dependencies${RESET} ...\n"
for portal in "${xdg[@]}"; do
    install_package "$portal" "$LOG"
||||||| 814e28a
##
printf "${NOTE} Installing xdg-desktop-portal-gtk...\n"  
for portal in "${xdg[@]}"; do
    install_package "$portal" 2>&1 | tee -a "$LOG"
    [ $? -ne 0 ] && { echo -e "\e[1A\e[K${ERROR} - $portal Package installation failed, Please check the installation logs"; exit 1; }
=======
# Remove old libexec path if exists
[[ -f "/usr/lib/xdg-desktop-portal-hyprland" ]] && sudo rm "/usr/lib/xdg-desktop-portal-hyprland"

# XDG-DESKTOP-PORTAL-HYPRLAND
printf "${NOTE} Installing ${SKY_BLUE}xdg-desktop-portal-hyprland dependencies${RESET}\n\n"

for PKG1 in "${xdg_deps[@]}"; do
  re_install_package "$PKG1" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    echo -e "\e[1A\e[K${ERROR} - $PKG1 Package installation failed, Please check the installation logs"
    exit 1
  fi
>>>>>>> 25.10-development
done

<<<<<<< HEAD
# Check if xdg-desktop-portal-hyprland directory exists and remove it
||||||| 814e28a
# Check if xdg-desktop-portal-hyprland folder exists and remove it
=======
# Clone, build, and install XDPH
printf "${NOTE} Cloning and Installing ${YELLOW}XDG Desktop Portal Hyprland $tag${RESET} ...\n"

# Check if xdg-desktop-portal-hyprland folder exists and remove it
>>>>>>> 25.10-development
if [ -d "xdg-desktop-portal-hyprland" ]; then
<<<<<<< HEAD
    rm -rf "xdg-desktop-portal-hyprland"
||||||| 814e28a
    printf "${NOTE} Removing existing xdg-desktop-portal-hyprland folder...\n"
    rm -rf "xdg-desktop-portal-hyprland"
=======
  printf "${NOTE} Removing existing xdg-desktop-portal-hyprland folder...\n"
  rm -rf "xdg-desktop-portal-hyprland" 2>&1 | tee -a "$LOG"
>>>>>>> 25.10-development
fi

<<<<<<< HEAD
# Clone and build xdg-desktop-portal-hyprland
printf "${NOTE} Installing ${SKY_BLUE}xdg-desktop-portal-hyprland $xdph_tag from source${RESET}"
if git clone --recursive -b $xdph_tag https://github.com/hyprwm/xdg-desktop-portal-hyprland; then
    cd xdg-desktop-portal-hyprland || exit 1
    cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build
    cmake --build build
    if sudo cmake --install build 2>&1 | tee -a "$MLOG"; then
        printf "${OK} ${MAGENTA}xdg-desktop-portal-hyprland $xdph_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}xdg-desktop-portal-hyprland $xdph_tag${RESET}" 2>&1 | tee -a "$MLOG"
    fi
    # Moving the additional logs to Install-Logs directory
    mv "$MLOG" ../Install-Logs/ || true
    cd ..
||||||| 814e28a
# Clone and build xdg-desktop-portal-hyprland
printf "${NOTE} Installing xdg-desktop-portal-hyprland...\n"
if git clone --branch v1.3.0 --recursive https://github.com/hyprwm/xdg-desktop-portal-hyprland; then
    cd xdg-desktop-portal-hyprland || exit 1
    make all
    if sudo make install 2>&1 | tee -a "$MLOG" ; then
        printf "${OK} xdg-desktop-portal-hyprland installed successfully.\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "${ERROR} Installation failed for xdg-desktop-portal-hyprland." 2>&1 | tee -a "$MLOG"
    fi
    #moving the addional logs to Install-Logs directory
    mv $MLOG ../Install-Logs/ || true 
    cd ..
=======
if git clone --recursive -b "$tag" "https://github.com/hyprwm/xdg-desktop-portal-hyprland.git"; then
  cd "xdg-desktop-portal-hyprland" || exit 1
  cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build
  cmake --build build -j "$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
  if sudo cmake --install build 2>&1 | tee -a "$MLOG"; then
    printf "${OK} ${MAGENTA}xdph $tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
  else
    echo -e "${ERROR} Installation failed for ${YELLOW}xdph $tag${RESET}" 2>&1 | tee -a "$MLOG"
  fi
  mv "$MLOG" ../Install-Logs/ || true
  cd ..
>>>>>>> 25.10-development
else
<<<<<<< HEAD
    echo -e "${ERROR} Download failed for ${YELLOW}xdg-desktop-portal-hyprland $xdph_tag${RESET}" 2>&1 | tee -a "$LOG"
||||||| 814e28a
    echo -e "${ERROR} Download failed for xdg-desktop-portal-hyprland." 2>&1 | tee -a "$LOG"
=======
  echo -e "${ERROR} Download failed for ${YELLOW}xdph $tag${RESET}" 2>&1 | tee -a "$LOG"
>>>>>>> 25.10-development
fi

printf "\n%.0s" {1..2}
