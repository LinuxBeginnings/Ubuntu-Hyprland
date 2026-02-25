#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# wallust - pywal colors replacement #
set -euo pipefail

# Optional pin. If empty, any installed version is accepted and we skip.
WALLUST_VERSION_TARGET="${WALLUST_VERSION:-}"

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_wallust.log"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG")"

# Ensure Cargo exists; install Rust only if missing
if ! command -v cargo >/dev/null 2>&1; then
  echo "${INFO} Installing ${YELLOW}Rust toolchain (cargo)${RESET} ..." | tee -a "$LOG"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal 2>&1 | tee -a "$LOG"
  source "$HOME/.cargo/env"
else
  source "$HOME/.cargo/env" || true
fi

printf "\n%.0s" {1..1}

# If wallust already installed and (optionally) matches target, skip
if command -v wallust >/dev/null 2>&1; then
  cur_ver="$(wallust --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+){1,3}' | head -1 || true)"
  if [ -z "$WALLUST_VERSION_TARGET" ] || [ "$cur_ver" = "$WALLUST_VERSION_TARGET" ]; then
    echo "${OK} wallust ${cur_ver:-unknown} already installed. Skipping." | tee -a "$LOG"
    exit 0
  fi
  echo "${INFO} Updating wallust from ${cur_ver:-unknown} -> ${WALLUST_VERSION_TARGET}" | tee -a "$LOG"
fi

# Install/upgrade Wallust using Cargo (cargo will update if already installed)
echo "${INFO} Installing ${MAGENTA}wallust${RESET} via cargo ..." | tee -a "$LOG"
cargo install wallust --locked 2>&1 | tee -a "$LOG"

# Place the binary under /usr/local/bin (preferred for locally built tools)
echo "Installing wallust to /usr/local/bin ..." | tee -a "$LOG"
sudo install -m 0755 "$HOME/.cargo/bin/wallust" /usr/local/bin/wallust 2>&1 | tee -a "$LOG"

echo "${OK} wallust installation complete." | tee -a "$LOG"

printf "\n%.0s" {1..2}
