#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Waybar - Build from source #

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the global functions script (provides REPO_ROOT/BUILD_SRC and color vars)
# Source BEFORE strict mode so tput/color setup in Global_functions.sh can't
# trigger -u (unbound variable) errors before REPO_ROOT is exported.
if ! source "$SCRIPT_DIR/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Fallback: derive REPO_ROOT from SCRIPT_DIR if Global_functions.sh didn't export it
REPO_ROOT="${REPO_ROOT:-"$(readlink -f "$SCRIPT_DIR/..")"}"
BUILD_ROOT="${BUILD_ROOT:-"$REPO_ROOT/build"}"
BUILD_SRC="${BUILD_SRC:-"$BUILD_ROOT/src"}"
BUILD_BIN="${BUILD_BIN:-"$BUILD_ROOT/bin"}"
export REPO_ROOT BUILD_ROOT BUILD_SRC BUILD_BIN
mkdir -p "$REPO_ROOT/Install-Logs" "$BUILD_SRC" "$BUILD_BIN"

# Enable strict mode now that globals are safely loaded
set -euo pipefail

# Log files
LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_waybar.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_waybar-build.log"

waybar_repo="https://github.com/Alexays/Waybar"
waybar_src_dir="$BUILD_SRC/Waybar"
UBUNTU_SOURCES="/etc/apt/sources.list.d/ubuntu.sources"

waybar_extra_deps=(
    build-essential
    meson
    ninja-build
    git
    libgtk-3-dev
    libgtkmm-3.0-dev
    libwayland-dev
    libjsoncpp-dev
    libsigc++-2.0-dev
    libfmt-dev
    libspdlog-dev
    libpulse-dev
    libpipewire-0.3-dev
    libnl-3-dev
    libnl-genl-3-dev
    libappindicator3-dev
    libdbusmenu-gtk3-dev
    libevdev-dev
    libmpdclient-dev
    libsndio-dev
    libupower-glib-dev
    libdisplay-info-dev
)

# ─── Check if waybar is already installed ─────────────────────────────────────
if command -v waybar &>/dev/null; then
    echo -e "${INFO} ${MAGENTA}waybar${RESET} is already installed at $(command -v waybar). Skipping build."
    exit 0
fi

# ─── Enable deb-src if not already enabled ────────────────────────────────────
printf "\n%s - Checking ${YELLOW}deb-src${RESET} availability...\n" "${NOTE}"
if [ -f "$UBUNTU_SOURCES" ]; then
    if grep -q "deb-src" "$UBUNTU_SOURCES"; then
        echo -e "${INFO} ${MAGENTA}deb-src${RESET} is already enabled. Skipping."
    else
        printf "%s - Enabling ${YELLOW}deb-src${RESET} in %s...\n" "${NOTE}" "$UBUNTU_SOURCES"
        sudo sed -i 's/Types: deb$/Types: deb deb-src/' "$UBUNTU_SOURCES" 2>&1 | tee -a "$LOG"
        echo -e "${OK} deb-src enabled in $UBUNTU_SOURCES"
    fi
else
    echo -e "${WARN} $UBUNTU_SOURCES not found — deb-src may not be available." | tee -a "$LOG"
fi

# ─── Update apt ───────────────────────────────────────────────────────────────
printf "\n%s - Running ${YELLOW}apt update${RESET}...\n" "${INFO}"
sudo apt update 2>&1 | tee -a "$LOG"

# ─── Extra build dependencies ─────────────────────────────────────────────────
printf "\n%s - Installing ${SKY_BLUE}waybar build dependencies${RESET}...\n" "${INFO}"
for PKG in "${waybar_extra_deps[@]}"; do
    install_package "$PKG"
done

# ─── apt build-dep for waybar ─────────────────────────────────────────────────
printf "\n%s - Running ${YELLOW}apt build-dep waybar${RESET}...\n" "${INFO}"
build_dep waybar

# ─── Clone or update Waybar source ───────────────────────────────────────────
cd "$BUILD_SRC" || { echo -e "${ERROR} Failed to change directory to $BUILD_SRC"; exit 1; }

printf "\n%s - Preparing ${YELLOW}Waybar${RESET} source in %s...\n" "${INFO}" "$waybar_src_dir"
if [ -d "$waybar_src_dir" ]; then
    printf "%s - Waybar source already exists, pulling latest...\n" "${INFO}"
    cd "$waybar_src_dir" || exit 1
    git pull 2>&1 | tee -a "$MLOG"
else
    printf "%s - Cloning ${YELLOW}Waybar${RESET} from %s...\n" "${INFO}" "$waybar_repo"
    if git clone --recursive "$waybar_repo" "$waybar_src_dir" 2>&1 | tee -a "$MLOG"; then
        cd "$waybar_src_dir" || exit 1
    else
        echo -e "${ERROR} Download failed for ${YELLOW}Waybar${RESET}" | tee -a "$LOG"
        exit 1
    fi
fi

# ─── Meson configure ──────────────────────────────────────────────────────────
printf "\n%s - Configuring ${YELLOW}Waybar${RESET} with meson...\n" "${INFO}"
if meson setup build --wipe 2>&1 | tee -a "$MLOG"; then
    echo -e "${OK} Meson configuration successful."
else
    echo -e "${ERROR} Meson configuration failed for ${YELLOW}Waybar${RESET}. Check $MLOG" | tee -a "$MLOG"
    exit 1
fi

# ─── Ninja build ──────────────────────────────────────────────────────────────
printf "\n%s - Building ${YELLOW}Waybar${RESET} with ninja...\n" "${INFO}"
if ninja -C build 2>&1 | tee -a "$MLOG"; then
    echo -e "${OK} Waybar build successful."
else
    echo -e "${ERROR} Build failed for ${YELLOW}Waybar${RESET}. Check $MLOG" | tee -a "$MLOG"
    exit 1
fi

# ─── Install ──────────────────────────────────────────────────────────────────
printf "\n%s - Installing ${YELLOW}Waybar${RESET}...\n" "${INFO}"
if sudo ninja -C build install 2>&1 | tee -a "$MLOG"; then
    echo -e "${OK} ${YELLOW}Waybar${RESET} installed successfully."
else
    echo -e "${ERROR} Installation failed for ${YELLOW}Waybar${RESET}. Check $MLOG" | tee -a "$MLOG"
    exit 1
fi

# ─── Verify ───────────────────────────────────────────────────────────────────
if command -v waybar &>/dev/null; then
    printf "%s ${GREEN}Waybar${RESET} is available at %s\n" "${OK}" "$(command -v waybar)"
else
    echo -e "${WARN} Waybar binary not found in PATH after install. Check $MLOG" | tee -a "$MLOG"
fi

cd "$REPO_ROOT" || exit 1

printf "\n%.0s" {1..2}
