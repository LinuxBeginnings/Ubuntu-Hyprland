#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Waybar - Remove APT package and build from source
#
# The Ubuntu/APT waybar package does NOT support the Hyprland Lua workflow.
# This script purges the apt-provided binary and builds the latest Waybar
# from source so that /usr/local/bin/waybar takes precedence.
# Unlike simply renaming the binary, purging prevents apt upgrades from
# silently restoring /usr/bin/waybar.

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
export REPO_ROOT BUILD_ROOT BUILD_SRC
mkdir -p "$REPO_ROOT/Install-Logs" "$BUILD_SRC"

# Enable strict mode now that globals are safely loaded
set -euo pipefail

# Log files
LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_waybar.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_waybar-build.log"

WAYBAR_REPO="https://github.com/Alexays/Waybar"
WAYBAR_SRC_DIR="$BUILD_SRC/Waybar"
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
    libayatana-appindicator3-dev
    libdbusmenu-gtk3-dev
    libevdev-dev
    libmpdclient-dev
    libsndio-dev
    libupower-glib-dev
    libdisplay-info-dev
)

# ─── Check if already source-built ───────────────────────────────────────────
# Source builds land in /usr/local/bin; APT installs to /usr/bin.
if [ -x "/usr/local/bin/waybar" ]; then
    echo -e "${INFO} Waybar is already source-built at /usr/local/bin/waybar. Skipping build."
    exit 0
fi

if command -v waybar &>/dev/null; then
    WAYBAR_VER_LINE="$(waybar --version 2>&1 | grep -i 'waybar v' || true)"
    if echo "$WAYBAR_VER_LINE" | grep -q -E "branch|g[0-9a-f]{7}"; then
        echo -e "${INFO} Waybar is already source-built at $(command -v waybar). Skipping build."
        exit 0
    fi
fi

# ─── Purge APT-provided waybar package(s) ────────────────────────────────────
# Purge rather than rename so that 'apt upgrade' cannot silently restore
# /usr/bin/waybar and override the source-built binary.
printf "\n%s - Checking for APT-provided ${YELLOW}waybar${RESET} package(s)...\n" "${NOTE}"
_purged=0
for _wpkg in waybar waybar-experimental; do
    if dpkg-query -W -f='${Status}' "$_wpkg" 2>/dev/null | grep -q "ok installed"; then
        printf "%s - Purging ${YELLOW}%s${RESET} (replaced by source build)...\n" "${NOTE}" "$_wpkg"
        sudo apt-get purge -y "$_wpkg" 2>&1 | tee -a "$LOG" || true
        _purged=1
    fi
done
if [ "$_purged" -eq 1 ]; then
    sudo apt-get autoremove -y 2>&1 | tee -a "$LOG" || true
    echo -e "${OK} APT waybar package(s) removed."
else
    echo -e "${INFO} No APT waybar package found; proceeding with source build."
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

printf "\n%s - Preparing ${YELLOW}Waybar${RESET} source in %s...\n" "${INFO}" "$WAYBAR_SRC_DIR"
if [ -d "$WAYBAR_SRC_DIR" ]; then
    printf "%s - Waybar source already exists, pulling latest...\n" "${INFO}"
    cd "$WAYBAR_SRC_DIR" || exit 1
    git pull 2>&1 | tee -a "$MLOG"
else
    printf "%s - Cloning ${YELLOW}Waybar${RESET} from %s...\n" "${INFO}" "$WAYBAR_REPO"
    if git clone --recursive "$WAYBAR_REPO" "$WAYBAR_SRC_DIR" 2>&1 | tee -a "$MLOG"; then
        cd "$WAYBAR_SRC_DIR" || exit 1
    else
        echo -e "${ERROR} Download failed for Waybar" | tee -a "$LOG"
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
