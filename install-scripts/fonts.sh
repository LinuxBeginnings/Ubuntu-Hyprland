#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Fonts Required #

fonts=(
  fonts-firacode
  fonts-font-awesome
  fonts-noto
  fonts-noto-cjk
  fonts-noto-color-emoji
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
init_script "fonts"


# Installation of main components
printf "\n%s - Installing necessary ${SKY_BLUE}fonts${RESET}.... \n" "${NOTE}"

for PKG1 in "${fonts[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}

# jetbrains nerd font. Necessary for waybar
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
# Maximum number of download attempts. The retry condition must come from curl,
# not tee, otherwise the loop breaks on the first attempt even after a failure.
MAX_ATTEMPTS=2
download_ok=0
for ((ATTEMPT = 1; ATTEMPT <= MAX_ATTEMPTS; ATTEMPT++)); do
    if curl -fOL "$DOWNLOAD_URL" >>"$LOG" 2>&1; then
        download_ok=1
        break
    fi
    echo "Download attempt $ATTEMPT failed. Retrying in 2 seconds..." | tee -a "$LOG"
    sleep 2
done

if [ "$download_ok" -eq 1 ] && [ -f JetBrainsMono.tar.xz ]; then
    # Only replace the existing copy after a successful download, so a failed
    # download never leaves the system without the font.
    rm -rf "$HOME/.local/share/fonts/JetBrainsMonoNerd"
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerd"
    if ! tar -xJkf JetBrainsMono.tar.xz -C "$HOME/.local/share/fonts/JetBrainsMonoNerd" 2>&1 | tee -a "$LOG"; then
        echo -e "${ERROR} Failed to extract ${YELLOW}JetBrains Mono Nerd Font${RESET}." | tee -a "$LOG"
    fi
else
    echo -e "${ERROR} Failed to download ${YELLOW}JetBrains Mono Nerd Font${RESET}. Check your connection." | tee -a "$LOG"
fi

# Fantasque Mono Nerd Font
if wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FantasqueSansMono.zip; then
    mkdir -p "$HOME/.local/share/fonts/FantasqueSansMono" && unzip -o -q "FantasqueSansMono.zip" -d "$HOME/.local/share/fonts/FantasqueSansMono" && echo "FantasqueSansMono installed successfully" | tee -a "$LOG"
else
    echo -e "\n${ERROR} Failed to download ${YELLOW}Fantasque Sans Mono Nerd Font${RESET} Please check your connection\n" | tee -a "$LOG"
fi

# Victor Mono-Font
if wget -q https://rubjo.github.io/victor-mono/VictorMonoAll.zip; then
    mkdir -p "$HOME/.local/share/fonts/VictorMono" && unzip -o -q "VictorMonoAll.zip" -d "$HOME/.local/share/fonts/VictorMono" && echo "Victor Font installed successfully" | tee -a "$LOG"
else
    echo -e "\n${ERROR} Failed to download ${YELLOW}Victor Mono Font${RESET} Please check your connection\n" | tee -a "$LOG"
fi

# Update font cache and log the output
fc-cache -v 2>&1 | tee -a "$LOG"

# clean up 
if [ -f "JetBrainsMono.tar.xz" ]; then
	rm -f JetBrainsMono.tar.xz 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
