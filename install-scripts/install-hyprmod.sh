#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# HyprMod - GTK4/libadwaita settings app for Hyprland #

set -o pipefail

HYPRMOD_INSTALL_URL="https://raw.githubusercontent.com/BlueManCZ/hyprmod/main/install.sh"
HYPRMOD_SOURCE="${HYPRMOD_SOURCE:-git+https://github.com/BlueManCZ/hyprmod.git}"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install, update, or uninstall hyprmod.

Options:
  -h, --help        Show this help message
  -u, --uninstall   Uninstall hyprmod
  -U, --update      Update hyprmod to the latest version

Without options, this script installs hyprmod when it is not already installed.

EOF
}

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi

# Repo root as cwd + absolute, collision-free log path
init_script "hyprmod"

# hyprmod is a Python GTK4/libadwaita app that its own installer puts in a uv or
# pipx virtualenv. Beyond the GTK4/adwaita runtime libraries it needs their
# GObject Introspection typelibs (python3-gi cannot import Gtk 4.0 or Adw 1
# without the gir1.2-* packages), and PyGObject is compiled from source because
# it publishes no wheels for the system Python - hence the -dev packages and a
# compiler. uv itself is bootstrapped by the upstream installer, so pipx is only
# the no-prompt alternative for that step.
hyprmod_deps=(
    python3
    python3-pip
    python3-venv
    python3-dev
    pipx
    libgtk-4-1
    gir1.2-gtk-4.0
    libadwaita-1-0
    gir1.2-adw-1
    libcairo2-dev
    libgirepository-2.0-dev
    gobject-introspection
    pkg-config
    build-essential
)

# Same check 03-Final-Check.sh uses: the binary may be in ~/.local/bin before
# that directory is on this shell's PATH.
hyprmod_path() {
    if command -v hyprmod >/dev/null 2>&1; then
        command -v hyprmod
    elif [ -x "$HOME/.local/bin/hyprmod" ]; then
        printf '%s\n' "$HOME/.local/bin/hyprmod"
    else
        return 1
    fi
}

install_hyprmod_deps() {
    local PKG
    if ! command -v apt >/dev/null 2>&1; then
        echo -e "${ERROR} apt was not found; hyprmod needs its dependencies installed manually." | tee -a "$LOG"
        return 1
    fi

    for PKG in "${hyprmod_deps[@]}"; do
        install_package "$PKG" || true
    done

    # Dependencies only: the upstream installer may still fail for reasons of its
    # own (network, uv), and those are reported by run_hyprmod_installer.
    if ! report_install_failures; then
        echo -e "${ERROR} hyprmod dependencies did not install; skipping hyprmod." | tee -a "$LOG"
        return 1
    fi
}

run_hyprmod_installer() { # run_hyprmod_installer <install|uninstall>
    local action="$1"

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${ERROR} curl was not found; cannot reach $HYPRMOD_INSTALL_URL" | tee -a "$LOG"
        return 1
    fi

    if [ "$action" = "uninstall" ]; then
        echo -e "${NOTE} Running the hyprmod uninstaller..." | tee -a "$LOG"
        HYPRMOD_SOURCE="$HYPRMOD_SOURCE" curl -LsSf "$HYPRMOD_INSTALL_URL" 2>&1 |
            sh -s -- --uninstall 2>&1 | tee -a "$LOG"
    else
        echo -e "${NOTE} Running the hyprmod installer (${YELLOW}$HYPRMOD_SOURCE${RESET})..." | tee -a "$LOG"
        # The upstream installer prompts on /dev/tty before bootstrapping uv, so
        # log its output without piping stdin (curl already owns stdin here).
        HYPRMOD_SOURCE="$HYPRMOD_SOURCE" curl -LsSf "$HYPRMOD_INSTALL_URL" 2>&1 |
            sh 2>&1 | tee -a "$LOG"
    fi
}

install_hyprmod() {
    if hyprmod_path >/dev/null; then
        echo -e "${INFO} ${MAGENTA}hyprmod${RESET} is already installed at $(hyprmod_path). Skipping." | tee -a "$LOG"
        return 0
    fi

    printf "\n%s - Installing ${SKY_BLUE}HyprMod${RESET} and its dependencies...\n" "${NOTE}"
    install_hyprmod_deps || return 1

    if ! run_hyprmod_installer install; then
        echo -e "${ERROR} hyprmod installation failed." | tee -a "$LOG"
        return 1
    fi

    local installed_path=""
    installed_path="$(hyprmod_path)" || {
        echo -e "${ERROR} hyprmod was installed but no 'hyprmod' command was found." | tee -a "$LOG"
        return 1
    }

    echo -e "${OK} ${YELLOW}HyprMod${RESET} installed at ${GREEN}${installed_path}${RESET}" | tee -a "$LOG"
    if ! command -v hyprmod >/dev/null 2>&1; then
        echo -e "${NOTE} Add ${YELLOW}\$HOME/.local/bin${RESET} to your PATH (or log out and back in) to run it." | tee -a "$LOG"
    fi
    echo -e "${NOTE} Launch HyprMod from the app menu, or run ${SKY_BLUE}hyprmod${RESET}." | tee -a "$LOG"
}

update_hyprmod() {
    printf "\n%s - Updating ${SKY_BLUE}HyprMod${RESET}...\n" "${NOTE}"
    install_hyprmod_deps || return 1

    if ! run_hyprmod_installer install; then
        echo -e "${ERROR} hyprmod update failed." | tee -a "$LOG"
        return 1
    fi
    echo -e "${OK} ${YELLOW}HyprMod${RESET} updated." | tee -a "$LOG"
}

uninstall_hyprmod() {
    if ! hyprmod_path >/dev/null; then
        echo -e "${INFO} hyprmod is not installed." | tee -a "$LOG"
        return 0
    fi

    printf "\n%s - Uninstalling ${SKY_BLUE}HyprMod${RESET}...\n" "${NOTE}"
    if ! run_hyprmod_installer uninstall; then
        echo -e "${ERROR} hyprmod uninstall failed." | tee -a "$LOG"
        return 1
    fi
    echo -e "${OK} ${YELLOW}HyprMod${RESET} uninstalled." | tee -a "$LOG"
}

case "${1:-}" in
"")
    install_hyprmod
    ;;
-h | --help)
    show_help
    ;;
-u | --uninstall)
    uninstall_hyprmod
    ;;
-U | --update)
    update_hyprmod
    ;;
*)
    echo -e "${ERROR} Unknown option: $1" | tee -a "$LOG"
    show_help
    exit 1
    ;;
esac

printf "\n%.0s" {1..1}
