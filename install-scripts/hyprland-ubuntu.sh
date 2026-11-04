#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# Install Hyprland and related packages from the Ubuntu repositories.
#
# Used when the community PPA cannot provide Hyprland for this release (or when
# --install-ubuntu is given). The PPA is removed first: a PPA enabled for
# another series leaves APT unable to install anything, including the Ubuntu
# packages this path needs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
    echo "[ERROR] Failed to change directory to $PARENT_DIR"
    exit 1
}

if [ -f "$(dirname "$(readlink -f "$0")")/Global_functions.sh" ]; then
    # shellcheck disable=SC1090
    source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland-ubuntu.log"

note() { echo -e "${NOTE} $*" | tee -a "$LOG"; }
info() { echo -e "${INFO} $*" | tee -a "$LOG"; }

printf "[INFO] Ensuring add-apt-repository is available...\n" | tee -a "$LOG"
sudo apt install -y software-properties-common | tee -a "$LOG"

if grep -R "cppiber.*hyprland" /etc/apt/sources.list "$APT_SOURCES_DIR" 2>/dev/null | grep -q .; then
    note "Removing PPA: ppa:cppiber/hyprland"
    sudo add-apt-repository -r -y ppa:cppiber/hyprland 2>&1 | tee -a "$LOG" || true
    sudo rm -f "$APT_SOURCES_DIR"/*cppiber*hyprland* 2>/dev/null || true
    sudo sed -i '/cppiber.*hyprland/d' /etc/apt/sources.list 2>/dev/null || true
fi

# Stale pins would keep APT on the removed PPA packages (best effort)
sudo rm -f /etc/apt/preferences.d/*hyprland* /etc/apt/preferences.d/*cppiber* 2>/dev/null || true

info "Running apt update"
sudo apt update 2>&1 | tee -a "$LOG"

# Make sure APT is not in a broken state before installing anything
sudo dpkg --configure -a 2>/dev/null | tee -a "$LOG" || true
sudo apt --fix-broken install -y 2>&1 | tee -a "$LOG" || true

# Replace PPA-only packages that the Ubuntu repositories do not carry, otherwise
# they keep pulling in the removed PPA as a dependency.
PPA_ONLY=(hyprutils hyprgraphics hyprcursor aquamarine hyprsunset)
for p in "${PPA_ONLY[@]}"; do
    if dpkg -l 2>/dev/null | grep -q "^ii  ${p} "; then
        if ! has_apt_candidate "$p"; then
            note "Purging PPA-only package with no Ubuntu candidate: $p"
            apt_candidate_report "$p" >>"$LOG" 2>&1
            sudo apt -y purge "$p" 2>&1 | tee -a "$LOG" || true
        fi
    fi
done

if ! has_apt_candidate hyprland; then
    echo -e "${ERROR} The Ubuntu repositories provide no hyprland candidate for this release, so Hyprland cannot be installed from them. Use the community PPA (--install-ppa) or see the README." | tee -a "$LOG"
    apt_candidate_report hyprland 2>&1 | tee -a "$LOG"
    record_hyprland_source ubuntu-failed "the Ubuntu repositories have no hyprland candidate for this release"
    exit 1
fi

info "Installing/Upgrading hyprland from Ubuntu repositories"
sudo apt install -y hyprland 2>&1 | tee -a "$LOG"
note "Ubuntu 24.04 ships an older Hyprland than the PPA build. The dotfiles are tested against the PPA, so expect to adjust some config."

PKGS=(
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprwayland-scanner
    xdg-desktop-portal-hyprland
)
for p in "${PKGS[@]}"; do
    if has_apt_candidate "$p"; then
        info "Installing/Upgrading $p from Ubuntu repositories"
        sudo apt install -y "$p" 2>&1 | tee -a "$LOG"
    else
        note "$p is not available in the Ubuntu repositories; skipping"
        apt_candidate_report "$p" >>"$LOG" 2>&1
    fi
done

# Keep the reason the PPA path was abandoned, for the final check summary
if [ "$(hyprland_source_field 1)" = "ppa-failed" ]; then
    record_hyprland_source ubuntu "$(hyprland_source_field 2)"
else
    record_hyprland_source ubuntu
fi

note "Repository-based Hyprland installation completed."
