#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# Add Hyprland PPA and install Hyprland stack from PPA
#
# The PPA only carries builds for the Ubuntu series it was enabled for, so a
# stale entry for another release makes `apt update` fail and makes a missing
# candidate say nothing about this release. The series is checked up front; a
# package the PPA does not carry here is skipped instead of failing the step.

set -euo pipefail

# Discover repo root and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
    echo "[ERROR] Failed to change directory to $PARENT_DIR"
    exit 1
}

# Optional helper functions (not required for apt upgrades, but source if present)
if [ -f "$(dirname "$(readlink -f "$0")")/Global_functions.sh" ]; then
    # shellcheck disable=SC1090
    source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland-ppa.log"

note() { echo -e "${NOTE} $*" | tee -a "$LOG"; }
info() { echo -e "${INFO} $*" | tee -a "$LOG"; }

printf "[INFO] Ensuring add-apt-repository is available...\n" | tee -a "$LOG"
sudo apt install -y software-properties-common | tee -a "$LOG"

# Add the PPA (idempotent)
if grep -R "cppiber.*hyprland" /etc/apt/sources.list "$APT_SOURCES_DIR" 2>/dev/null | grep -q .; then
    note "Hyprland PPA already present; continuing"
else
    printf "[INFO] Adding Hyprland PPA (cppiber/hyprland)...\n" | tee -a "$LOG"
    if ! sudo add-apt-repository -y ppa:cppiber/hyprland 2>&1 | tee -a "$LOG"; then
        echo -e "${ERROR} Failed to add the Hyprland PPA. It may not support this Ubuntu release yet." | tee -a "$LOG"
        record_hyprland_source ppa-failed "the PPA could not be added"
        exit 1
    fi
fi

# Report a series mismatch before apt touches the PPA
if ! ppa_series_ok; then
    series_list="$(ppa_suites | tr '\n' ' ' | sed 's/ $//')"
    codename="$(ubuntu_codename)"
    echo -e "${ERROR} The Hyprland PPA is enabled for ${series_list}, but this system runs ${codename}. The PPA has no packages for this release. Use --install-ubuntu instead." | tee -a "$LOG"
    record_hyprland_source ppa-failed "the PPA is enabled for ${series_list}, this system runs ${codename}"
    exit 1
fi

printf "[INFO] Running apt update after adding PPA...\n" | tee -a "$LOG"
if ! sudo apt update 2>&1 | tee -a "$LOG"; then
    echo -e "${ERROR} apt update failed, so the PPA package lists may be missing or stale. See the install log." | tee -a "$LOG"
    record_hyprland_source ppa-failed "apt update failed"
    exit 1
fi

# Verify that the PPA provides a candidate for hyprland on this series
if ! has_apt_candidate hyprland; then
    echo -e "${ERROR} The PPA does not provide a hyprland candidate for this Ubuntu release. Use --install-ubuntu instead." | tee -a "$LOG"
    apt_candidate_report hyprland 2>&1 | tee -a "$LOG"
    record_hyprland_source ppa-failed "the PPA has no hyprland candidate for this release"
    exit 1
fi

printf "[INFO] Installing Hyprland from PPA...\n" | tee -a "$LOG"
sudo apt install -y hyprland | tee -a "$LOG"

printf "[INFO] Installing remaining Hyprland-related packages from PPA...\n" | tee -a "$LOG"
PKGS=(
    hypridle
    hyprlock
    hyprsunset
    hyprpaper
    hyprpicker
    hyprwayland-scanner
    xdg-desktop-portal-hyprland
)
for p in "${PKGS[@]}"; do
    if has_apt_candidate "$p"; then
        info "Installing/Upgrading $p from PPA"
        sudo apt install -y "$p" 2>&1 | tee -a "$LOG"
    else
        note "$p is not available from the PPA for this release; skipping"
        apt_candidate_report "$p" >>"$LOG" 2>&1
    fi
done

record_hyprland_source ppa
printf "[OK] Hyprland PPA setup and package installation complete.\n" | tee -a "$LOG"
