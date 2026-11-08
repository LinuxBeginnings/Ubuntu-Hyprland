#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Quickshell - build from source and package as an AppImage
#
# Ubuntu 24.04 ships Qt 6.4.2, but quickshell needs >= 6.6 *and* private Qt
# headers (qtdeclarative-private, qtwayland-private). There is no quickshell
# package in noble, and the avengemedia/danklinux PPA only publishes for
# 25.10/26.04/26.10. Building Qt from source takes hours, so this script uses
# the official Qt binaries (built on Ubuntu 24.04, glibc 2.39) as the SDK and
# bundles the result into a self-contained AppImage.
#
# Everything lands under build/ (gitignored); the AppImage path is printed at
# the end. Override with QT_VERSION=6.8.x or QUICKSHELL_VERSION=0.3.x.
#
# Licensing: the AppImage redistributes quickshell and Qt, both under the GNU
# LGPLv3, so it ships the license texts and a notice naming the exact versions
# and source URLs (usr/share/doc/quickshell) and keeps both as separate shared
# objects that can be swapped out, which is what LGPLv3 relinking asks for.
# Those files must stay in place if the AppImage is redistributed.
#
# QUICKSHELL_INSTALL=0 builds the AppImage without installing it.

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the global functions script (provides REPO_ROOT/BUILD_SRC and color vars)
if ! source "$SCRIPT_DIR/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

REPO_ROOT="${REPO_ROOT:-"$(readlink -f "$SCRIPT_DIR/..")"}"
BUILD_ROOT="${BUILD_ROOT:-"$REPO_ROOT/build"}"
BUILD_SRC="${BUILD_SRC:-"$BUILD_ROOT/src"}"
export REPO_ROOT BUILD_ROOT BUILD_SRC
mkdir -p "$REPO_ROOT/Install-Logs" "$BUILD_SRC"

# Enable strict mode now that globals are safely loaded
set -euo pipefail

LOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_quickshell.log"
MLOG="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_quickshell-build.log"

QT_VERSION="${QT_VERSION:-6.8.3}"
QUICKSHELL_VERSION="${QUICKSHELL_VERSION:-0.3.2}"
QUICKSHELL_REPO="https://github.com/quickshell-mirror/quickshell"

QT_ROOT="$BUILD_ROOT/qt/$QT_VERSION/gcc_64"
QS_SRC_DIR="$BUILD_SRC/quickshell"
QS_BUILD_DIR="$BUILD_ROOT/quickshell-build"
APPDIR="$BUILD_ROOT/quickshell-AppDir"
OUT_DIR="${QUICKSHELL_OUT_DIR:-$BUILD_ROOT/appimage}"
TOOLS_DIR="$BUILD_ROOT/appimage-tools"
AQT_VENV="$BUILD_ROOT/aqt-venv"
APPIMAGE="$OUT_DIR/quickshell-$QUICKSHELL_VERSION-x86_64.AppImage"

qs_deps=(
    build-essential
    cmake
    ninja-build
    git
    curl
    file
    xz-utils
    python3-venv
    pkg-config
    patchelf
    libdrm-dev
    libwayland-dev
    libwayland-bin
    wayland-protocols
    libxcb1-dev
    libxcb-util-dev
    libxcb-cursor-dev
    libxcb-icccm4-dev
    libxcb-xkb-dev
    libxkbcommon-dev
    libpipewire-0.3-dev
    libpam0g-dev
    libpolkit-agent-1-dev
    libjemalloc-dev
    libcli11-dev
    libgbm-dev
    libvulkan-dev
    spirv-tools
    libunwind-dev
    libdwarf-dev
    libzstd-dev
    libgl1-mesa-dev
    libegl1-mesa-dev
    libfontconfig1-dev
    libfreetype-dev
    libfuse2t64
)

# ─── Install the AppImage for the desktop ───────────────────────────────────
# The image is installed as-is: quickshell must run against the Qt it was built
# with, so it cannot use the system Qt. The AppImage runtime needs FUSE 2, which
# is not part of a default Ubuntu 24.04 install, so the wrapper falls back to the
# runtime's extract-and-run mode when FUSE 2 is missing.
install_appimage() {
    local dest_dir=/usr/local/bin
    local dest="$dest_dir/quickshell.AppImage"
    local wrap="$dest_dir/quickshell"
    if ! sudo install -d -m 0755 "$dest_dir" >>"$LOG" 2>&1 \
        || ! sudo install -m 0755 "$APPIMAGE" "$dest" >>"$LOG" 2>&1; then
        echo -e "${ERROR} Could not install the AppImage to $dest. See ${SKY_BLUE}$LOG${RESET}"
        return 1
    fi
    # shellcheck disable=SC2016 # $APP/$@ are expanded by the wrapper, not here
    if ! sudo tee "$wrap" >/dev/null <<WRAP
#!/bin/sh
# Wrapper for the quickshell AppImage built by install-scripts/quickshell.sh.
APP="\${QUICKSHELL_APPIMAGE:-$dest}"
FUSE2="\$(ldconfig -p 2>/dev/null | grep -c 'libfuse\.so\.2' || true)"
if [ "\${FUSE2:-0}" -gt 0 ] && [ -e /dev/fuse ]; then
    exec "\$APP" "\$@"
fi
APPIMAGE_EXTRACT_AND_RUN=1 exec "\$APP" "\$@"
WRAP
    then
        echo -e "${ERROR} Could not write the wrapper $wrap. See ${SKY_BLUE}$LOG${RESET}"
        return 1
    fi
    sudo chmod 0755 "$wrap"
    printf "%s Installed ${MAGENTA}quickshell${RESET} (AppImage: %s, wrapper: %s)\n" "${OK}" "$dest" "$wrap"
}

# ─── Skip when a working AppImage is already there ───────────────────────────
# Existence is not enough: a build made against the wrong Qt (or a mangled
# AppRun) is still a file, and skipping on it would hide the breakage.
if [ -x "$APPIMAGE" ] && APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGE" --version >/dev/null 2>&1; then
    echo -e "${INFO} Quickshell $QUICKSHELL_VERSION AppImage already built at $APPIMAGE. Skipping."
    if [ "${QUICKSHELL_INSTALL:-1}" != "0" ] && [ ! -x /usr/local/bin/quickshell ]; then
        install_appimage || exit 1
    fi
    exit 0
fi

printf "\n%s - Installing ${SKY_BLUE}quickshell build dependencies${RESET}...\n" "${INFO}"
for PKG in "${qs_deps[@]}"; do
    install_package "$PKG"
done

# ─── Qt SDK (official binaries, no account required via aqtinstall) ───────────
# The official Qt 6.8 binaries are built on Ubuntu 24.04, so they match noble's
# glibc. Qt is required at runtime too: quickshell uses private Qt APIs and must
# run against the exact Qt it was compiled against, which is why the AppImage
# bundles it.
if [ -x "$QT_ROOT/bin/qmake" ]; then
    echo -e "${INFO} Qt ${MAGENTA}$QT_VERSION${RESET} already present in $QT_ROOT. Skipping download."
else
    printf "\n%s - Fetching ${YELLOW}Qt $QT_VERSION${RESET} (official binaries, ~1.6 GB)...\n" "${INFO}"
    if [ ! -x "$AQT_VENV/bin/aqt" ]; then
        python3 -m venv "$AQT_VENV" >>"$LOG" 2>&1
        "$AQT_VENV/bin/pip" -q install aqtinstall >>"$LOG" 2>&1
    fi
    if ! "$AQT_VENV/bin/aqt" install-qt linux desktop "$QT_VERSION" linux_gcc_64 \
        --outputdir "$BUILD_ROOT/qt" \
        -m qt5compat qtimageformats qtshadertools >>"$LOG" 2>&1; then
        echo -e "${ERROR} Qt $QT_VERSION download failed. See ${SKY_BLUE}$LOG${RESET}"
        exit 1
    fi
    if [ ! -x "$QT_ROOT/bin/qmake" ]; then
        echo -e "${ERROR} Qt $QT_VERSION did not install where expected ($QT_ROOT)."
        exit 1
    fi
fi

export PATH="$QT_ROOT/bin:$PATH"

# ─── Source ──────────────────────────────────────────────────────────────────
mkdir -p "$BUILD_SRC"
if [ -d "$QS_SRC_DIR/.git" ]; then
    printf "%s - Using existing quickshell source, checking out v%s...\n" "${INFO}" "$QUICKSHELL_VERSION"
    if ! { git -C "$QS_SRC_DIR" fetch --depth=1 origin "tag" "v$QUICKSHELL_VERSION" \
        && git -C "$QS_SRC_DIR" checkout -f "v$QUICKSHELL_VERSION"; } >>"$LOG" 2>&1; then
        # Building master here would produce an AppImage labelled with a version
        # it does not contain, so stop instead.
        echo -e "${ERROR} Could not check out quickshell v$QUICKSHELL_VERSION. See ${SKY_BLUE}$LOG${RESET}"
        exit 1
    fi
else
    printf "%s - Cloning ${YELLOW}quickshell${RESET} v%s...\n" "${INFO}" "$QUICKSHELL_VERSION"
    if ! git clone --depth=1 --branch "v$QUICKSHELL_VERSION" "$QUICKSHELL_REPO" "$QS_SRC_DIR" >>"$LOG" 2>&1; then
        echo -e "${ERROR} Download failed for quickshell. See ${SKY_BLUE}$LOG${RESET}"
        exit 1
    fi
fi

# ─── Configure ───────────────────────────────────────────────────────────────
# VENDOR_CPPTRACE avoids needing a cpptrace package on noble; jemalloc keeps the
# QML engine's memory use flat (quickshell's recommendation).
printf "\n%s - Configuring ${YELLOW}quickshell${RESET}...\n" "${INFO}"
if ! cmake -GNinja -B "$QS_BUILD_DIR" -S "$QS_SRC_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$QT_ROOT" \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DDISTRIBUTOR="Ubuntu-Hyprland 24.04 (AppImage build)" \
    -DVENDOR_CPPTRACE=ON \
    -DUSE_JEMALLOC=ON >>"$MLOG" 2>&1; then
    echo -e "${ERROR} CMake configuration failed for quickshell. See ${SKY_BLUE}$MLOG${RESET}"
    exit 1
fi

# ─── Build ───────────────────────────────────────────────────────────────────
printf "\n%s - Building ${YELLOW}quickshell${RESET} (this takes a few minutes)...\n" "${INFO}"
if ! cmake --build "$QS_BUILD_DIR" -j"$(nproc)" >>"$MLOG" 2>&1; then
    echo -e "${ERROR} Build failed for quickshell. See ${SKY_BLUE}$MLOG${RESET}"
    exit 1
fi
echo -e "${OK} quickshell $QUICKSHELL_VERSION built."

# ─── AppDir ──────────────────────────────────────────────────────────────────
printf "\n%s - Assembling ${YELLOW}AppDir${RESET}...\n" "${INFO}"
rm -rf "$APPDIR"
DESTDIR="$APPDIR" cmake --install "$QS_BUILD_DIR" >>"$MLOG" 2>&1
# Install-time junk: headers, static libs and CMake metadata are not needed.
rm -rf "$APPDIR/usr/include" "$APPDIR/usr/lib/x86_64-linux-gnu/cmake" \
       "$APPDIR/usr/lib/x86_64-linux-gnu/pkgconfig"
find "$APPDIR/usr/lib" \( -name '*.a' -o -name '*.prl' \) -delete 2>/dev/null || true

cat > "$APPDIR/usr/share/applications/org.quickshell.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Quickshell
Comment=Flexible toolkit for creating desktop shells with QtQuick
Exec=quickshell
Icon=org.quickshell
Terminal=false
Categories=Utility;
DESKTOP

# ─── AppImage tooling (extracted, so FUSE is not needed to run them) ──────────
mkdir -p "$TOOLS_DIR"
fetch_tool() { # fetch_tool <url> <target-dir> <name>
    # Split deliberately: all words of one `local` call are expanded before any
    # assignment happens, so $name would be unbound in the same statement.
    local url="$1" dir="$2" name="$3"
    local appimage="$TOOLS_DIR/$name.AppImage"
    if [ -x "$dir/AppRun" ]; then
        return 0
    fi
    if ! curl -sfL --retry 5 --retry-delay 3 --retry-all-errors --max-time 180 "$url" -o "$appimage"; then
        echo -e "${ERROR} Could not download $name. See ${SKY_BLUE}$LOG${RESET}"
        return 1
    fi
    chmod +x "$appimage"
    ( cd "$TOOLS_DIR" && ./"$name.AppImage" --appimage-extract >/dev/null 2>&1 )
    mv "$TOOLS_DIR/squashfs-root" "$dir"
}

if ! fetch_tool "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage" "$TOOLS_DIR/linuxdeploy" "linuxdeploy-x86_64"; then
    exit 1
fi
if ! fetch_tool "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage" "$TOOLS_DIR/qt-plugin" "linuxdeploy-plugin-qt-x86_64"; then
    exit 1
fi
if ! fetch_tool "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" "$TOOLS_DIR/appimagetool" "appimagetool-x86_64"; then
    exit 1
fi
if [ ! -s "$TOOLS_DIR/runtime-x86_64" ]; then
    curl -sfL --retry 5 --retry-delay 3 --retry-all-errors --max-time 180 \
        "https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64" \
        -o "$TOOLS_DIR/runtime-x86_64" \
        || { echo -e "${ERROR} Could not download the AppImage runtime."; exit 1; }
fi

# ─── Bundle Qt: libraries, plugins, QML modules ───────────────────────────────
printf "\n%s - Bundling ${YELLOW}Qt $QT_VERSION${RESET} into the AppDir...\n" "${INFO}"
mkdir -p "$TOOLS_DIR/bin"
ln -sf ../qt-plugin/AppRun "$TOOLS_DIR/bin/linuxdeploy-plugin-qt"
# The Qt plugin asks qmake where Qt lives. Without $QT_ROOT/bin first in PATH it
# answers with noble's Qt 6.4.2 and the AppImage bundles the wrong Qt: the binary
# then dies with "version `Qt_6.8' not found". LD_LIBRARY_PATH is needed for the
# same reason on linuxdeploy's own dependency pass, which runs before the plugin
# and otherwise resolves Qt through ldconfig.
if ! PATH="$QT_ROOT/bin:$TOOLS_DIR/bin:$PATH" QMAKE="$QT_ROOT/bin/qmake" \
    LD_LIBRARY_PATH="$QT_ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$TOOLS_DIR/linuxdeploy/AppRun" \
    --appdir "$APPDIR" \
    --plugin qt \
    --desktop-file "$APPDIR/usr/share/applications/org.quickshell.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/org.quickshell.svg" >>"$MLOG" 2>&1; then
    echo -e "${ERROR} linuxdeploy failed to bundle Qt. See ${SKY_BLUE}$MLOG${RESET}"
    exit 1
fi

# linuxdeploy cannot see QML imports quickshell resolves at runtime, and the
# Wayland platform plugin never gets pulled in from the ELF dependencies alone.
# Both are required: quickshell only runs on Wayland.
mkdir -p "$APPDIR/usr/qml" "$APPDIR/usr/plugins"
cp -a "$QT_ROOT/qml/." "$APPDIR/usr/qml/"
cp -a "$QT_ROOT/plugins/platforms/." "$APPDIR/usr/plugins/platforms/"
for plug in wayland-shell-integration wayland-decoration-client wayland-graphics-integration-client imageformats; do
    [ -d "$QT_ROOT/plugins/$plug" ] && cp -a "$QT_ROOT/plugins/$plug" "$APPDIR/usr/plugins/"
done
# SVG icons come from QtSvg, which is loaded at runtime, never linked.
for lib in "$QT_ROOT"/lib/libQt6Svg.so.*; do
    [ -e "$lib" ] && cp -a "$lib" "$APPDIR/usr/lib/" || true
done

# Replace linuxdeploy's AppRun (a symlink to the binary: writing through it
# would overwrite the executable) with one that exports the import paths.
rm -f "$APPDIR/AppRun"
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/sh
HERE="${APPDIR:-$(dirname "$(readlink -f "$0")")}"
export QML_IMPORT_PATH="$HERE/usr/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export QML2_IMPORT_PATH="$QML_IMPORT_PATH"
export QT_PLUGIN_PATH="$HERE/usr/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
exec "$HERE/usr/bin/quickshell" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# ─── Make sure the Qt in the AppDir is the Qt we built against ───────────────
# linuxdeploy's own dependency pass runs before the Qt plugin and can resolve Qt
# through ldconfig; the plugin then skips those paths and the AppImage ends up
# with noble's Qt 6.4. Copying the real libraries over the top is deterministic
# whatever linuxdeploy decided.
for lib in "$QT_ROOT"/lib/libQt6*.so.*; do
    base="$(basename "$lib")"
    case "$base" in
    *.so.[0-9]) cp -Lf "$lib" "$APPDIR/usr/lib/$base" ;;
    esac
done
for lib in "$APPDIR"/usr/lib/libQt6*.so.[0-9]; do
    patchelf --set-rpath '$ORIGIN' "$lib"
done

# ─── Guard: the bundled Qt must be the Qt we built against ───────────────────
# A mismatch here is silent until the AppImage is run on a machine whose Qt is
# older, where it fails with "version `Qt_6.8' not found".
# grep -q is deliberate avoided here: it closes the pipe early, and under
# pipefail strings' SIGPIPE turns a correct build into a failure.
qt_suffix="${QT_VERSION%.*}"
qt_hits="$(strings "$APPDIR/usr/lib/libQt6Core.so.6" 2>/dev/null | grep -cF "Qt_$qt_suffix" || true)"
if [ "${qt_hits:-0}" -eq 0 ]; then
    echo -e "${ERROR} The bundled Qt6Core is not Qt $QT_VERSION. See ${SKY_BLUE}$MLOG${RESET}"
    exit 1
fi

# ─── Licenses ────────────────────────────────────────────────────────────────
# Necessary for redistribution, not for running: both quickshell and Qt are
# LGPLv3, and the AppImage conveys copies of them. LGPLv3 wants the full license
# texts (LGPLv3 incorporates GPLv3 by reference), a notice of which versions are
# shipped and where their source can be had, and libraries the user can replace.
DOC_DIR="$APPDIR/usr/share/doc/quickshell"
mkdir -p "$DOC_DIR"
for f in LICENSE LICENSE-GPL; do
    [ -f "$QS_SRC_DIR/$f" ] && cp -f "$QS_SRC_DIR/$f" "$DOC_DIR/$f"
done
copy_license_text() { # copy_license_text <name> <url>
    local name="$1" url="$2"
    if [ -f "/usr/share/common-licenses/$name" ]; then
        cp -f "/usr/share/common-licenses/$name" "$DOC_DIR/$name"
    elif ! curl -sfL --retry 3 --retry-all-errors --max-time 60 "$url" -o "$DOC_DIR/$name"; then
        rm -f "$DOC_DIR/$name"
        echo -e "${WARN} Could not fetch the $name text; the notice still gives its URL."
    fi
}
copy_license_text LGPL-3 https://www.gnu.org/licenses/lgpl-3.0.txt
copy_license_text GPL-3 https://www.gnu.org/licenses/gpl-3.0.txt

cat > "$DOC_DIR/THIRD-PARTY-NOTICES.txt" <<NOTICE
Quickshell AppImage - third-party notices
=========================================

This AppImage contains:

  quickshell $QUICKSHELL_VERSION
      Project: https://github.com/quickshell-mirror/quickshell
      Source:  $QUICKSHELL_REPO/archive/refs/tags/v$QUICKSHELL_VERSION.tar.gz
      License: GNU Lesser General Public License v3 (see LICENSE)

  Qt $QT_VERSION
      Project: https://www.qt.io/
      Source:  https://download.qt.io/official_releases/qt/${QT_VERSION%.*}/$QT_VERSION/submodules/
      License: GNU Lesser General Public License v3 (see LGPL-3 and LICENSE-GPL)

Both are used unmodified, except that the Qt libraries in usr/lib have their
RPATH set to \$ORIGIN so they resolve from the AppImage rather than from the
host system. Qt is used under the LGPLv3 option of its license; its GPLv3 and
commercial options are not used here.

LGPLv3 allows this combination only if the libraries can be replaced with a
modified version. Both stay separate shared objects in usr/lib, they are not
linked into usr/bin/quickshell, so they can be swapped and the image repacked:

    ./quickshell-$QUICKSHELL_VERSION-x86_64.AppImage --appimage-extract
    cp /path/to/your/libQt6Core.so.6 squashfs-root/usr/lib/
    ARCH=x86_64 appimagetool squashfs-root quickshell-custom.AppImage

The build recipe for this image is install-scripts/quickshell.sh in
https://github.com/LinuxBeginnings/Ubuntu-Hyprland (branch 24.04).
NOTICE

# ─── Pack ────────────────────────────────────────────────────────────────────
printf "\n%s - Creating ${YELLOW}AppImage${RESET}...\n" "${INFO}"
mkdir -p "$OUT_DIR"
if ! ARCH=x86_64 "$TOOLS_DIR/appimagetool/AppRun" --no-appstream \
    --runtime-file "$TOOLS_DIR/runtime-x86_64" \
    "$APPDIR" "$APPIMAGE" >>"$MLOG" 2>&1; then
    echo -e "${ERROR} appimagetool failed. See ${SKY_BLUE}$MLOG${RESET}"
    exit 1
fi
chmod +x "$APPIMAGE"

# ─── Verify ──────────────────────────────────────────────────────────────────
if APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGE" --version >>"$MLOG" 2>&1; then
    printf "%s ${GREEN}AppImage${RESET} is ready: %s (%s)\n" "${OK}" "$APPIMAGE" \
        "$(du -h "$APPIMAGE" | cut -f1)"
    printf "%s Run it with a config: %s -p ~/.config/quickshell\n" "${NOTE}" "$APPIMAGE"
else
    echo -e "${ERROR} The AppImage was built but does not run. See ${SKY_BLUE}$MLOG${RESET}"
    exit 1
fi

if [ "${QUICKSHELL_INSTALL:-1}" != "0" ]; then
    install_appimage || exit 1
fi
printf "%s License notices (quickshell and bundled Qt, both LGPLv3): %s inside the AppImage\n" \
    "${NOTE}" "usr/share/doc/quickshell"

printf "\n%.0s" {1..2}
