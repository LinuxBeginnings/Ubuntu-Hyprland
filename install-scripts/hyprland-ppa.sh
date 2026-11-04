#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Enable the Hyprland PPA and install packages (best-effort; guards for 26.04 support)

set -euo pipefail


# shellcheck source=install-scripts/Global_functions.sh
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

# Repo root as cwd + absolute, collision-free log path
init_script "hyprland-ppa"

note() { echo -e "${NOTE} $*" | tee -a "$LOG"; }
info() { echo -e "${INFO} $*" | tee -a "$LOG"; }

# Ensure repo tooling exists
install_package software-properties-common 2>&1 | tee -a "$LOG" || true

# Add the PPA (idempotent)
if ! grep -R "cppiber.*hyprland" /etc/apt/sources.list "$APT_SOURCES_DIR" 2>/dev/null | grep -q .; then
    note "Adding PPA: ppa:cppiber/hyprland"
    if ! sudo add-apt-repository -y ppa:cppiber/hyprland 2>&1 | tee -a "$LOG"; then
        echo -e "${ERROR} Failed to add the Hyprland PPA. It may not support this Ubuntu release yet." | tee -a "$LOG"
        exit 1
    fi
else
    note "Hyprland PPA already present; continuing"
fi

# The PPA only carries builds for the series it was enabled for. When that is
# not the series we run, `apt update` can fail on the PPA and a missing
# candidate says nothing about this release, so report the mismatch up front.
if ! ppa_series_ok; then
    series_list="$(ppa_suites | tr '\n' ' ' | sed 's/ $//')"
    codename="$(ubuntu_codename)"
    echo -e "${ERROR} The Hyprland PPA is enabled for ${series_list}, but this system runs ${codename}. The PPA has no packages for this release. Use --install-ubuntu instead." | tee -a "$LOG"
    record_hyprland_source ppa-failed "the PPA is enabled for ${series_list}, this system runs ${codename}"
    exit 1
fi

info "Running apt update"
if ! sudo apt update 2>&1 | tee -a "$LOG"; then
    echo -e "${ERROR} apt update failed, so the package lists may be missing or stale. See the install log." | tee -a "$LOG"
    record_hyprland_source ppa-failed "apt update failed"
    exit 1
fi

# Verify that the PPA provides a candidate for hyprland on this series
if ! has_apt_candidate hyprland; then
    echo -e "${ERROR} PPA does not provide a hyprland candidate for this Ubuntu release. Use --install-ubuntu instead." | tee -a "$LOG"
    apt_candidate_report hyprland 2>&1 | tee -a "$LOG"
    record_hyprland_source ppa-failed "the PPA has no hyprland candidate for this release"
    exit 1
fi

# Install hyprland and common companions from PPA when available
PKGS=(
    hyprland
    hypridle
    hyprlock
    hyprwayland-scanner
    xdg-desktop-portal-hyprland
)

for p in "${PKGS[@]}"; do
    if has_apt_candidate "$p"; then
        info "Installing/Upgrading $p from PPA"
        sudo apt install -y "$p" 2>&1 | tee -a "$LOG"
    else
        note "$p not available from PPA for this release; skipping"
        apt_candidate_report "$p" >>"$LOG" 2>&1
    fi
done

record_hyprland_source ppa
note "PPA-based Hyprland installation completed."
