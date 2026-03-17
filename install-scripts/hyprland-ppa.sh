<<<<<<< HEAD
#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Add Hyprland PPA and install Hyprland stack from PPA

set -euo pipefail

# Discover repo root and source helpers
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "[ERROR] Failed to change directory to $PARENT_DIR"; exit 1; }

# Optional helper functions (not required for apt upgrades, but source if present)
if [ -f "$(dirname "$(readlink -f "$0")")/Global_functions.sh" ]; then
  # shellcheck disable=SC1090
  source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland-ppa.log"

printf "[INFO] Ensuring add-apt-repository is available...\n" | tee -a "$LOG"
sudo apt install -y software-properties-common | tee -a "$LOG"

# Add the PPA, then update package lists (required to see PPA versions)
printf "[INFO] Adding Hyprland PPA (cppiber/hyprland)...\n" | tee -a "$LOG"
sudo add-apt-repository -y ppa:cppiber/hyprland | tee -a "$LOG"

printf "[INFO] Running apt update after adding PPA...\n" | tee -a "$LOG"
sudo apt update | tee -a "$LOG"

# Install Hyprland first, then the rest
printf "[INFO] Installing Hyprland from PPA...\n" | tee -a "$LOG"
sudo apt install -y hyprland | tee -a "$LOG"

printf "[INFO] Installing remaining Hyprland-related packages from PPA...\n" | tee -a "$LOG"
sudo apt install -y \
  hypridle \
  hyprlock \
  hyprsunset \
  hyprpaper \
  hyprpicker \
  waybar \
  hyprutils \
  hyprwayland-scanner \
  hyprgraphics \
  hyprcursor \
  aquamarine \
  hyprland-qtutils \
  xdg-desktop-portal-hyprland | tee -a "$LOG"

printf "[OK] Hyprland PPA setup and package installation complete.\n" | tee -a "$LOG"
||||||| 814e28a
=======
#!/bin/bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Install Hyprland and related packages from cppiber/hyprland PPA (prebuilt binaries)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || exit 1

# shellcheck source=install-scripts/Global_functions.sh
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland-ppa.log"

note() { echo -e "${NOTE} $*" | tee -a "$LOG"; }
info() { echo -e "${INFO} $*" | tee -a "$LOG"; }

install_package software-properties-common 2>&1 | tee -a "$LOG" || true

if ! grep -R "^deb .*cppiber.*hyprland" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q .; then
  note "Adding PPA: ppa:cppiber/hyprland"
  sudo add-apt-repository -y ppa:cppiber/hyprland 2>&1 | tee -a "$LOG" || true
else
  info "PPA already present; skipping add-apt-repository"
fi

info "Running apt update"
sudo apt update 2>&1 | tee -a "$LOG"

# Remove conflicting Ubuntu package if present (overlaps /usr/bin/hyprcursor-util)
if dpkg -l | grep -q '^ii  hyprcursor-util '; then
  info "Removing conflicting hyprcursor-util (Ubuntu repo) to allow libhyprcursor1 from PPA"
  sudo apt -y purge hyprcursor-util 2>&1 | tee -a "$LOG" || true
  sudo apt -y autoremove 2>&1 | tee -a "$LOG" || true
fi

# Ensure APT is not in a broken state before proceeding
sudo dpkg --configure -a 2>/dev/null | tee -a "$LOG" || true
sudo apt --fix-broken install -y 2>&1 | tee -a "$LOG" || true

# Install hyprland first to satisfy dependencies cleanly
if apt-cache policy hyprland | grep -q "Candidate: \\S"; then
  info "Installing/Upgrading hyprland from apt"
  sudo apt install -y hyprland 2>&1 | tee -a "$LOG"
else
  note "hyprland not found in APT archives; skipping"
fi

# Install remaining PPA components (exclude hyprland-qtutils and hyprland-qt-support for now)
PKGS=(
  hypridle
  hyprlock
  hyprsunset
  hyprpaper
  hyprpicker
  waybar
  hyprutils
  hyprwayland-scanner
  hyprgraphics
  hyprcursor
  aquamarine
  hyprland-qtutils
  xdg-desktop-portal-hyprland
)

for p in "${PKGS[@]}"; do
  if apt-cache policy "$p" | grep -q "Candidate: \\S"; then
    info "Installing/Upgrading $p from apt"
    sudo apt install -y "$p" 2>&1 | tee -a "$LOG"
  else
    note "$p not found in APT archives; skipping"
  fi
done

note "PPA-based Hyprland installation completed."
>>>>>>> 25.10-development
