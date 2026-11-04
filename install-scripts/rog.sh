#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# ASUS ROG ) #

asus=(
  power-profiles-daemon
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Surface failures from `cmd | tee` instead of tee's exit status
set -o pipefail

# Repo root as cwd + absolute, collision-free log path (kept absolute so the
# builds below can cd without losing the log)
init_script "rog"

# Installing enhancemet
for PKG1 in "${asus[@]}"; do
  if ! install_package "$PKG1" 2>&1 | tee -a "$LOG"; then
    echo -e "\033[1A\033[K${ERROR} - $PKG1 Package installation failed, Please check the installation logs"
    exit 1
  fi
done

printf " enabling power-profiles-daemon...\n"
sudo systemctl enable power-profiles-daemon 2>&1 | tee -a "$LOG"

# Function to handle the installation and log messages
# Returns non-zero when the project could not be cloned or installed, so the
# caller can fail the step instead of the script ending 0 after an error.
install_and_log() {
  local project_name="$1"
  local git_url="$2"
  local rc=0
  
  printf "${NOTE} Installing $project_name\n"

  if git clone "$git_url" "$project_name"; then
    cd "$project_name" || exit 1
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tee -a "$LOG"; then
      echo "${WARN} Rust toolchain install failed for $project_name." | tee -a "$LOG"
    fi
    source "$HOME/.cargo/env"
    make

    if sudo make install 2>&1 | tee -a "$LOG"; then
      printf "${OK} $project_name installed successfully.\n"
      if [ "$project_name" == "supergfxctl" ]; then
        # Enable supergfxctl
        sudo systemctl enable --now supergfxd 2>&1 | tee -a "$LOG"
      fi
    else
      echo -e "${ERROR} Installation failed for $project_name."
      rc=1
    fi

    cd - || exit 1
  else
    echo -e "${ERROR} Cloning $project_name from $git_url failed."
    rc=1
  fi
  return "$rc"
}

# Both projects are attempted even if the first fails; the script then reports
# the failure through its exit status.
rog_failed=0

# Download and build asusctl
install_and_log "asusctl" "https://gitlab.com/asus-linux/asusctl.git" || rog_failed=1

# Download and build supergfxctl
install_and_log "supergfxctl" "https://gitlab.com/asus-linux/supergfxctl.git" || rog_failed=1

printf "\n%.0s" {1..2}

exit "$rog_failed"