#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# hypidle #

idle=(
    libsdbus-c++-dev
)

#specific branch or release
idle_tag="v0.1.6"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the global functions script (provides REPO_ROOT/BUILD_SRC)
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Work in build/src to keep repo root clean
cd "$BUILD_SRC" || { echo "${ERROR} Failed to change directory to $BUILD_SRC"; exit 1; }

# Set the name of the log file to include the current date and time (under repo root)
LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hypridle.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_hypridle2.log"

# Installation of dependencies
printf "\n%s - Installing ${YELLOW}hypridle dependencies${RESET} .... \n" "${INFO}"

for PKG1 in "${idle[@]}"; do
  re_install_package "$PKG1" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    echo -e "\e[1A\e[K${ERROR} - ${YELLOW}$PKG1${RESET} Package installation failed, Please check the installation logs"
    exit 1
  fi
done

# Check if hypridle directory exists and remove it
if [ -d "hypridle" ]; then
    rm -rf "hypridle"
fi

# Clone and build 
printf "${INFO} Installing ${YELLOW}hypridle $idle_tag${RESET} ...\n"
if git clone --recursive -b $idle_tag https://github.com/hyprwm/hypridle.git; then
    cd hypridle || exit 1
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
	cmake --build ./build --config Release --target hypridle -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
    if sudo cmake --install ./build 2>&1 | tee -a "$MLOG" ; then
        printf "${OK} ${MAGENTA}hypridle $idle_tag${RESET} installed successfully.\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "${ERROR} Installation failed for ${YELLOW}hypridle $idle_tag${RESET}" 2>&1 | tee -a "$MLOG"
    fi
    cd ..
else
    echo -e "${ERROR} Download failed for ${YELLOW}hypridle $idle_tag${RESET}" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
