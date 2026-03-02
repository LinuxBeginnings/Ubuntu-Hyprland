#!/usr/bin/bash

# Automated force-fix for PPA collisions
if [[ $(lsb_release -rs) == "26.04" ]]; then
    echo "Detected Ubuntu 26.04 - Forcing PPA library overwrites..."
    sudo apt-get install -y hyprland ||
        sudo dpkg -i --force-overwrite /var/cache/apt/archives/*.deb &&
        sudo apt-get install -f -y
fi
