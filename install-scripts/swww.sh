#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# SWWW - Wallpaper Utility #
set -euo pipefail

# Resolve locations and load globals early (defines ${OK}, ${INFO}, etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi

# Pin to last supported release (and numeric for comparisons)
swww_tag="v0.11.2"
swww_min="0.11.2"

# Version compare helper (dpkg preferred; fallback to sort -V)
version_ge() {
  local a="$1" b="$2"
  if command -v dpkg >/dev/null 2>&1; then
    dpkg --compare-versions "$a" ge "$b"
    return $?
  fi
  [ "$(printf '%s\n%s\n' "$b" "$a" | sort -V | tail -n1)" = "$a" ]
}

# Check if 'swww' is installed and sufficient
if command -v swww &>/dev/null; then
    SWWW_VERSION=$( (swww --version 2>/dev/null || swww -V 2>/dev/null || true) | grep -oE '[0-9]+(\.[0-9]+){1,3}' | head -1)
    if [ -n "$SWWW_VERSION" ] && version_ge "$SWWW_VERSION" "$swww_min"; then
        echo -e "${OK} ${MAGENTA}swww ${SWWW_VERSION}${RESET} detected (>= ${swww_min}). Skipping installation."
        exit 0
    else
        echo -e "${INFO} swww ${SWWW_VERSION:-unknown} found; upgrading to ${swww_tag}."
    fi
else
    echo -e "${NOTE} ${MAGENTA}swww${RESET} is not installed. Proceeding with installation."
fi

swww=(
    liblz4-dev
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
    echo "${ERROR} Failed to change directory to $PARENT_DIR"
    exit 1
}

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_swww.log"
MLOG="install-$(date +%d-%H%M%S)_swww2.log"

# Installation of swww compilation needed
printf "\n%s - Installing ${SKY_BLUE}swww $swww_tag and dependencies${RESET} .... \n" "${NOTE}"

for PKG1 in "${swww[@]}"; do
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}

# Fetch sources at exact tag
if [ -d "swww" ]; then
    cd swww || exit 1
    git fetch --tags --force 2>&1 | tee -a "$MLOG"
    git checkout -f "$swww_tag" 2>&1 | tee -a "$MLOG"
    git reset --hard "$swww_tag" 2>&1 | tee -a "$MLOG"
else
    if git clone --recursive -b "$swww_tag" https://github.com/LGFae/swww.git; then
        cd swww || exit 1
    else
        echo -e "${ERROR} Download failed for ${YELLOW}swww $swww_tag${RESET}" 2>&1 | tee -a "$LOG"
        exit 1
    fi
fi

# Proceed with the rest of the installation steps
source "$HOME/.cargo/env" || true

cargo build --release 2>&1 | tee -a "$MLOG"

# Remove any old distro-installed copies to avoid path confusion
for f in /usr/bin/swww /usr/bin/swww-daemon; do
    if [ -f "$f" ]; then
        sudo rm -f "$f"
    fi
done

# Install locally built binaries under /usr/local/bin
sudo install -m 0755 target/release/swww /usr/local/bin/swww 2>&1 | tee -a "$MLOG"
sudo install -m 0755 target/release/swww-daemon /usr/local/bin/swww-daemon 2>&1 | tee -a "$MLOG"

# Copy bash completions
sudo mkdir -p /usr/share/bash-completion/completions 2>&1 | tee -a "$MLOG"
sudo cp -r completions/swww.bash /usr/share/bash-completion/completions/swww 2>&1 | tee -a "$MLOG"

# Copy zsh completions
sudo mkdir -p /usr/share/zsh/site-functions 2>&1 | tee -a "$MLOG"
sudo cp -r completions/_swww /usr/share/zsh/site-functions/_swww 2>&1 | tee -a "$MLOG"

# Moving logs into main Install-Logs
mv "$MLOG" ../Install-Logs/ || true
cd - || exit 1

printf "\n%.0s" {1..2}

