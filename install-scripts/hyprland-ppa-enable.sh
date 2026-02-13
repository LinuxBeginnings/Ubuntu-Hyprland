#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# Enable the Hyprland PPA and install packages (best-effort; guards for 26.04 support)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || exit 1

# shellcheck source=install-scripts/Global_functions.sh
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland-ppa-enable.log"

note() { echo -e "${NOTE} $*" | tee -a "$LOG"; }
info() { echo -e "${INFO} $*" | tee -a "$LOG"; }

# Ensure repo tooling exists
install_package software-properties-common 2>&1 | tee -a "$LOG" || true

# Add the PPA (idempotent)
if ! grep -R "^deb .*cppiber.*hyprland" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q .; then
  note "Adding PPA: ppa:cppiber/hyprland"
  if ! sudo add-apt-repository -y ppa:cppiber/hyprland 2>&1 | tee -a "$LOG"; then
    echo -e "${ERROR} Failed to add the Hyprland PPA. It may not support this Ubuntu release yet." | tee -a "$LOG"
    exit 1
  fi
else
  note "Hyprland PPA already present; continuing"
fi

info "Running apt update"
sudo apt update 2>&1 | tee -a "$LOG"

# Verify that the PPA provides a candidate for hyprland on this series
if ! apt-cache policy hyprland | awk '/Candidate:/ {print $2}' | grep -vq '(none)'; then
  echo -e "${ERROR} PPA does not provide a hyprland candidate for this Ubuntu release. Use --install-ubuntu instead." | tee -a "$LOG"
  exit 1
fi

# Install hyprland and common companions from PPA when available
PKGS=(
  hyprland
  hypridle
  hyprlock
  hyprwayland-scanner
  hyprland-qtutils
  xdg-desktop-portal-hyprland
)

for p in "${PKGS[@]}"; do
  if apt-cache policy "$p" | grep -q "Candidate: \\S"; then
    info "Installing/Upgrading $p from PPA"
    sudo apt install -y "$p" 2>&1 | tee -a "$LOG"
  else
    note "$p not available from PPA for this release; skipping"
  fi
done

note "PPA-based Hyprland installation completed."
