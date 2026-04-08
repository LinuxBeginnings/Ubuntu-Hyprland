#!/bin/bash
# 💫 https://github.com/LinuxBeginnings 💫 #
# main dependencies #
# 22 Aug 2024 - NOTE will trim this more down

# Ensure Universe repo is enabled (needed for some -dev packages)
if command -v add-apt-repository >/dev/null 2>&1; then
    sudo add-apt-repository -y universe || true
    sudo apt update || true
fi

# Detect Ubuntu version (fallback to /etc/os-release when not exported)
if [ -z "${UBUNTU_VERSION_ID:-}" ] && [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    UBUNTU_VERSION_ID="${VERSION_ID:-}"
fi

is_version_ge() {
    local current="$1"
    local target="$2"
    [ -n "$current" ] && dpkg --compare-versions "$current" ge "$target"
}

# packages neeeded
dependencies=()
hyprland_dep=()

if [ "$UBUNTU_VERSION_ID" = "24.04" ]; then
    dependencies=(
        build-essential
        cmake
        cmake-extras
        curl
        findutils
        gawk
        gettext
        gir1.2-graphene-1.0
        git
        glslang-tools
        gobject-introspection
        golang
        hwdata
        jq
        libavcodec-dev
        libavformat-dev
        libavutil-dev
        libcairo2-dev
        libdeflate-dev
        libdisplay-info-dev
        libdrm-dev
        libegl-dev
        libegl1-mesa-dev
        libgbm-dev
        libgdk-pixbuf-2.0-dev
        libgdk-pixbuf2.0-bin
        libgirepository1.0-dev
        libgl1-mesa-dev
        libgraphene-1.0-0
        libgraphene-1.0-dev
        libgtk-3-dev
        libgulkan-dev
        libinih-dev
        libinput-dev
        libjbig-dev
        libjpeg-dev
        libjpeg62-dev
        liblerc-dev
        libliftoff-dev
        liblzma-dev
        libnotify-bin
        libpam0g-dev
        libpango1.0-dev
        libpipewire-0.3-dev
        libqt6svg6
        libseat-dev
        libstartup-notification0-dev
        libswresample-dev
        libsystemd-dev
        libtiff-dev
        libtiffxx6
        libtomlplusplus-dev
        libudev-dev
        libvkfft-dev
        libvulkan-dev
        libvulkan-volk-dev
        libwayland-dev
        libwebp-dev
        libxcb-composite0-dev
        libxcb-cursor-dev
        libxcb-dri3-dev
        libxcb-ewmh-dev
        libxcb-icccm4-dev
        libxcb-present-dev
        libxcb-render-util0-dev
        libxcb-res0-dev
        libxcb-util-dev
        libxcb-xinerama0-dev
        libxcb-xinput-dev
        libxcb-xkb-dev
        libxkbcommon-dev
        libxkbcommon-x11-dev
        libxkbregistry-dev
        libxml2-dev
        libxxhash-dev
        make
        meson
        ninja-build
        nm-tray # applet for systray
        openssl
        psmisc
        python3-mako
        python3-markdown
        python3-markupsafe
        python3-yaml
        python3-pyquery
        qt6-base-dev
        rsync
        scdoc
        seatd
        spirv-tools
        unzip
        vulkan-validationlayers
        wayland-protocols
        xdg-desktop-portal
        xwayland
        bc
    )
elif [ "$UBUNTU_VERSION_ID" = "26.04" ]; then
    dependencies=(
        build-essential
        cmake
        cmake-extras
        curl
        findutils
        gawk
        gettext
        git
        glslang-tools
        gobject-introspection
        golang
        hwdata
        jq
        pkg-config
        libmpdclient-dev
        libnl-3-dev
        libasound2-dev
        libstartup-notification0-dev
        libwayland-client++1
        libwayland-dev
        libcairo-5c-dev
        libcairo2-dev
        libsdbus-c++-bin
        libegl-dev
        libegl1-mesa-dev
        libdrm-dev
        libgbm-dev
        libinput-dev
        libudev-dev
        libseat-dev
        libdisplay-info-dev
        libliftoff-dev
        libpixman-1-dev
        libtomlplusplus-dev
        libpango1.0-dev
        libgdk-pixbuf-2.0-dev
        libxcb-keysyms1-dev
        libwayland-client0
        libxcb-ewmh-dev
        libxcb-cursor-dev
        libxcb-icccm4-dev
        libxcb-composite0-dev
        libxcb-res0-dev
        libxcb-xfixes0-dev
        libxcb-render0-dev
        libxcb-randr0-dev
        libxcb-render-util0-dev
        libxcb-util-dev
        libxcb-xkb-dev
        libxcb-xinerama0-dev
        libxkbcommon-dev
        libxkbcommon-x11-dev
        libxcursor-dev
        meson
        ninja-build
        nm-tray
        openssl
        psmisc
        python3-mako
        python3-markdown
        python3-markupsafe
        python3-yaml
        python3-pyquery
        qt6-base-dev
        qt6-base-private-dev
        qt6-wayland-dev
        qt6-wayland-private-dev
        qt6-declarative-dev
        qml6-module-qtcore
        qml6-module-qtquick-layouts
        qt6-tools-dev
        qt6-tools-dev-tools
        rsync
        spirv-tools
        unzip
        vulkan-validationlayers
        vulkan-utility-libraries-dev
        wayland-protocols
        xdg-desktop-portal
        xwayland
    )

    # hyprland dependencies (runtime libs only; do NOT install hyprcursor-util or libhyprcursor-dev to avoid conflicts with PPA's libhyprcursor1)
    hyprland_dep=(
        bc
        binutils
        libc6
        libcairo2
        libdisplay-info2
        libdrm2
        hyprland-guiutils
        libpam0g-dev
    )
else
    dependencies=(
        build-essential
        cmake
        cmake-extras
        curl
        findutils
        gawk
        gettext
        git
        glslang-tools
        gobject-introspection
        golang
        hwdata
        jq
        pkg-config
        libmpdclient-dev
        libnl-3-dev
        libasound2-dev
        libstartup-notification0-dev
        libwayland-client++1
        libwayland-dev
        libcairo-5c-dev
        libcairo2-dev
        libsdbus-c++-bin
        libegl-dev
        libegl1-mesa-dev
        libdrm-dev
        libgbm-dev
        libinput-dev
        libudev-dev
        libseat-dev
        libdisplay-info-dev
        libliftoff-dev
        libpixman-1-dev
        libtomlplusplus-dev
        libpango1.0-dev
        libgdk-pixbuf-2.0-dev
        libxcb-keysyms1-dev
        libwayland-client0
        libxcb-ewmh-dev
        libxcb-cursor-dev
        libxcb-icccm4-dev
        libxcb-composite0-dev
        libxcb-res0-dev
        libxcb-xfixes0-dev
        libxcb-render0-dev
        libxcb-randr0-dev
        libxcb-render-util0-dev
        libxcb-util-dev
        libxcb-xkb-dev
        libxcb-xinerama0-dev
        libxkbcommon-dev
        libxkbcommon-x11-dev
        libxcursor-dev
        meson
        ninja-build
        nm-tray
        openssl
        psmisc
        python3-mako
        python3-markdown
        python3-markupsafe
        python3-yaml
        python3-pyquery
        qt6-base-dev
        qt6-base-private-dev
        qt6-wayland-dev
        qt6-wayland-private-dev
        qt6-declarative-dev
        qml6-module-qtcore
        qml6-module-qtquick-layouts
        qt6-tools-dev
        qt6-tools-dev-tools
        rsync
        spirv-tools
        unzip
        vulkan-validationlayers
        vulkan-utility-libraries-dev
        wayland-protocols
        xdg-desktop-portal
        xwayland
    )

    # hyprland dependencies (runtime libs only; do NOT install hyprcursor-util or libhyprcursor-dev to avoid conflicts with PPA's libhyprcursor1)
    hyprland_dep=(
        bc
        binutils
        libc6
        libcairo2
        libdisplay-info2
        libdrm2
        libpam0g-dev
    )
fi

build_dep=(
    wlroots
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
    echo "${ERROR} Failed to change directory to $PARENT_DIR"
    exit 1
}

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_dependencies.log"

# Proactively remove conflicting distro dev packages when using source-built libs
# (avoid overshadowing /usr/local hyprutils/hyprlang)
conflicts=(
    libhyprutils-dev
    libhyprlang-dev
)
for PKG in "${conflicts[@]}"; do
    uninstall_package "$PKG" 2>&1 | tee -a "$LOG" || true
done

# Proactively remove conflicting Ubuntu package only when using PPA (overlaps /usr/bin/hyprcursor-util)
if [ "${HYPR_USE_PPA:-0}" = "1" ] && dpkg -l | grep -q '^ii  hyprcursor-util '; then
    echo "${INFO} Removing conflicting hyprcursor-util (Ubuntu repo) to allow libhyprcursor1 from PPA" | tee -a "$LOG"
    sudo apt -y purge hyprcursor-util 2>&1 | tee -a "$LOG" || true
    sudo apt -y autoremove 2>&1 | tee -a "$LOG" || true
fi

# Installation of main dependencies
printf "\n%s - Installing ${SKY_BLUE}main dependencies....${RESET} \n" "${NOTE}"

for PKG1 in "${dependencies[@]}" "${hyprland_dep[@]}"; do
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}

for PKG1 in "${build_dep[@]}"; do
    build_dep "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}
