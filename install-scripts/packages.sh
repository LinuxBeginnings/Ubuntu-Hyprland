#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Single package manifest for the installer.
#
# Leaf file: defines arrays only, prints nothing and has no side effects, so it
# is safe to source from 01-hypr-pkgs.sh and 03-Final-Check.sh alike.
#
# WARNING! If you remove packages from hypr_required, dotfiles may not work
# properly. Ensure any package added here is present in the official
# Debian/Ubuntu repositories for the supported release.

# The arrays are this file's whole purpose: they are read by the scripts that
# source it, so "unused" here is expected.
# shellcheck disable=SC2034

# Packages needed by the dotfiles. Installed by 01-hypr-pkgs.sh and verified by
# 03-Final-Check.sh, so the installer and the final check cannot drift apart.
hypr_required=(
    cliphist
    ffmpeg
    7zip
    jq
    poppler-utils
    fd-find
    ripgrep
    fzf
    zoxide
    fastfetch
    grim
    gvfs
    gvfs-backends
    inxi
    imagemagick
    kitty
    lua5.4
    nano
    network-manager
    pavucontrol
    pulseaudio-utils
    playerctl
    polkit-kde-agent-1
    python3-requests
    python3-pip
    qt5ct
    libqt5quick5
    libqt5qml5
    qt-style-kvantum
    qt-style-kvantum-themes
    qt6-declarative-dev
    qt6ct
    slurp
    swappy
    sway-notification-center
    unzip
    wget
    wl-clipboard
    wlogout
    xdg-user-dirs
    xdg-utils
    yad
)

# The following packages can be deleted. however, dotfiles may not work properly
hypr_optional=(
    brightnessctl
    btop
    cava
    loupe
    gnome-system-monitor
    mousepad
    mpv
    mpv-mpris
    nwg-look
    nwg-displays
    nvtop
    pamixer
    qalculate-gtk
    xfce-polkit
    # Ubuntu 26.04 ships the Qt utilities as hyprland-qtutils (provides
    # hyprland-dialog); hyprland-guiutils only appears in 26.10+, where this
    # name is the transitional dummy package that pulls it in.
    hyprland-qtutils
)

# packages to force reinstall
hypr_force=(
    imagemagick
    wayland-protocols
)

# List of packages to uninstall as it conflicts with swaync or causing swaync to not function properly
hypr_uninstall=(
    mako
    rofi
    cargo
)

# Verified by 03-Final-Check.sh although they are installed by a dedicated
# script (hyprland-*.sh, yazi.sh) rather than by 01-hypr-pkgs.sh.
final_check_extra=(
    hyprland
    hyprland-qtutils
    yazi
)
