#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# main dependencies #
# 22 Aug 2024 - NOTE will trim this more down

# Ensure Universe repo is enabled (needed for some -dev packages)
if command -v add-apt-repository >/dev/null 2>&1; then
    sudo add-apt-repository -y universe || true
    sudo apt update || true
fi

# packages neeeded
dependencies=(
    build-essential
    cmake
    cmake-extras
    curl
    findutils
    gawk
    gettext
    git
    glslang-tools
    gobject-introspection
    golang
    hwdata
    jq
<<<<<<< HEAD
    libavcodec-dev
    libavformat-dev
    libavutil-dev
    libcairo2-dev
    libdeflate-dev
    libdisplay-info-dev
    libdrm-dev
    libegl-dev
    libegl1-mesa-dev
    libgbm-dev
    libgdk-pixbuf-2.0-dev
    libgdk-pixbuf2.0-bin
    libgirepository1.0-dev
    libgl1-mesa-dev
    libgraphene-1.0-0
    libgraphene-1.0-dev
    libgtk-3-dev
    libgulkan-dev
    libinih-dev
    libinput-dev
    libjbig-dev
    libjpeg-dev
    libjpeg62-dev
    liblerc-dev
    libliftoff-dev
    liblzma-dev
    libnotify-bin
    libpam0g-dev
    libpango1.0-dev
    libpipewire-0.3-dev
    libqt6svg6
    libseat-dev
||||||| 814e28a
    libavcodec-dev
    libavformat-dev
    libavutil-dev
    libcairo2-dev
    libdeflate-dev
    libdisplay-info-dev
    libdrm-dev
    libegl1-mesa-dev
    libgbm-dev
    libgdk-pixbuf-2.0-dev
    libgdk-pixbuf2.0-bin
    libgirepository1.0-dev
    libgl1-mesa-dev
    libgraphene-1.0-0
    libgraphene-1.0-dev
    libgtk-3-dev
    libgulkan-dev
    libinih-dev
    libinput-dev
    libjbig-dev
    libjpeg-dev
    libjpeg62-dev
    liblerc-dev
    libliftoff-dev
    liblzma-dev
    libnotify-bin
    libpam0g-dev
    libpango1.0-dev
    libpipewire-0.3-dev
    libqt6svg6
    libseat-dev
=======
    pkg-config
    libmpdclient-dev
    libnl-3-dev
    libasound2-dev
>>>>>>> 25.10-development
    libstartup-notification0-dev
    libwayland-client++1
    libwayland-dev
    libcairo-5c-dev
    libcairo2-dev
    libsdbus-c++-bin
    libegl-dev
    libegl1-mesa-dev
    libdrm-dev
    libgbm-dev
    libinput-dev
    libudev-dev
    libseat-dev
    libdisplay-info-dev
    libliftoff-dev
    libpixman-1-dev
    libtomlplusplus-dev
    libpango1.0-dev
    libgdk-pixbuf-2.0-dev
    libxcb-keysyms1-dev
    libwayland-client0
    libxcb-ewmh-dev
    libxcb-cursor-dev
    libxcb-icccm4-dev
    libxcb-composite0-dev
    libxcb-res0-dev
    libxcb-xfixes0-dev
    libxcb-render0-dev
    libxcb-randr0-dev
    libxcb-render-util0-dev
    libxcb-util-dev
    libxcb-xkb-dev
    libxcb-xinerama0-dev
    libxkbcommon-dev
    libxkbcommon-x11-dev
    libxcursor-dev
    meson
    ninja-build
<<<<<<< HEAD
    nm-tray # applet for systray
||||||| 814e28a
=======
    nm-tray
>>>>>>> 25.10-development
    openssl
    psmisc
    python3-mako
    python3-markdown
    python3-markupsafe
    python3-yaml
    python3-pyquery
    qt6-base-dev
<<<<<<< HEAD
    rsync
    scdoc
    seatd
||||||| 814e28a
    scdoc
    seatd
=======
    rsync
    qt6-base-private-dev
    qt6-wayland-dev
    qt6-wayland-private-dev
    qt6-declarative-dev
    qml6-module-qtcore
    qml6-module-qtquick-layouts
    qt6-tools-dev
    qt6-tools-dev-tools
>>>>>>> 25.10-development
    spirv-tools
    unzip
    vulkan-validationlayers
    vulkan-utility-libraries-dev
    wayland-protocols
    xdg-desktop-portal
    xwayland
    hyprland-guiutils
    bc
)

build_dep=(
    wlroots
)

# hyprland dependencies (runtime libs only; do NOT install hyprcursor-util or libhyprcursor-dev to avoid conflicts with PPA's libhyprcursor1)
hyprland_dep=(
    bc
    binutils
    libc6
    libcairo2
    libdisplay-info2
    libdrm2
    libpam0g-dev
    hyprland-guiutils
)

build_dep=(
    wlroots
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
    echo "${ERROR} Failed to change directory to $PARENT_DIR"
    exit 1
}

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_dependencies.log"

<<<<<<< HEAD
# Installation of main dependencies
printf "\n%s - Installing ${SKY_BLUE}main dependencies....${RESET} \n" "${NOTE}"

for PKG1 in "${dependencies[@]}"; do
    install_package "$PKG1" "$LOG"
||||||| 814e28a
# Installation of main dependencies
printf "\n%s - Installing main dependencies.... \n" "${NOTE}"

for PKG1 in "${dependencies[@]}"; do
  install_package "$PKG1" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    echo -e "\e[1A\e[K${ERROR} - $PKG1 Package installation failed, Please check the installation logs"
    exit 1
  fi
=======
# Proactively remove conflicting distro dev packages when using source-built libs
# (avoid overshadowing /usr/local hyprutils/hyprlang)
conflicts=(
    libhyprutils-dev
    libhyprlang-dev
)
for PKG in "${conflicts[@]}"; do
    uninstall_package "$PKG" 2>&1 | tee -a "$LOG" || true
>>>>>>> 25.10-development
done

<<<<<<< HEAD
printf "\n%.0s" {1..1}
||||||| 814e28a
# Install dependencies for wlroots
sudo apt build-dep wlroots
export PATH=$PATH:/usr/local/go/bin
=======
# Proactively remove conflicting Ubuntu package if present (overlaps /usr/bin/hyprcursor-util)
if dpkg -l | grep -q '^ii  hyprcursor-util '; then
    echo "${INFO} Removing conflicting hyprcursor-util (Ubuntu repo) to allow libhyprcursor1 from PPA" | tee -a "$LOG"
    sudo apt -y purge hyprcursor-util 2>&1 | tee -a "$LOG" || true
    sudo apt -y autoremove 2>&1 | tee -a "$LOG" || true
fi
>>>>>>> 25.10-development

<<<<<<< HEAD
for PKG1 in "${build_dep[@]}"; do
    build_dep "$PKG1" "$LOG"
done
||||||| 814e28a
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
=======
# Installation of main dependencies
printf "\n%s - Installing ${SKY_BLUE}main dependencies....${RESET} \n" "${NOTE}"
>>>>>>> 25.10-development

<<<<<<< HEAD
printf "\n%.0s" {1..2}
||||||| 814e28a
clear
=======
for PKG1 in "${dependencies[@]}" "${hyprland_dep[@]}"; do
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}

for PKG1 in "${build_dep[@]}"; do
    build_dep "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}
>>>>>>> 25.10-development
