#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# KooL Ubuntu 26.04 - Hyprland uninstall script #
# Run with --help for the non-interactive options.

# Only clear a real terminal, so piped/unattended runs stay readable
[ -t 1 ] && clear

# Set some colors for output messages. Skipped when there is no terminal (or
# TERM is unset), as in the install scripts.
if [ -n "${TERM:-}" ] && command -v tput >/dev/null 2>&1 && tput sgr0 >/dev/null 2>&1; then
    _setaf() { tput setaf "$1"; }
    RESET="$(tput sgr0)"
else
    _setaf() { :; }
    RESET=""
fi
OK="$(_setaf 2)[OK]$RESET"
ERROR="$(_setaf 1)[ERROR]$RESET"
NOTE="$(_setaf 3)[NOTE]$RESET"
INFO="$(_setaf 4)[INFO]$RESET"
WARN="$(_setaf 1)[WARN]$RESET"
CAT="$(_setaf 6)[ACTION]$RESET"
MAGENTA="$(_setaf 5)"
ORANGE="$(_setaf 214)"
WARNING="$(_setaf 1)"
YELLOW="$(_setaf 3)"
GREEN="$(_setaf 2)"
BLUE="$(_setaf 4)"
SKY_BLUE="$(_setaf 6)"

# ─── CLI ────────────────────────────────────────────────────────────────────
ASSUME_YES=0
DRY_RUN=0
SELECT_ALL=0
NONINTERACTIVE=0
PACKAGES_ARG=""
DIRS_ARG=""

usage() {
    cat <<EOF
Usage: ./uninstall.sh [options]

With no options the script asks interactively which packages and directories to
remove, and offers to restore backups.

Options:
  -y, --yes            Do not ask for confirmation (needs --all/--packages/--dirs)
      --all            Select every listed package and directory
      --packages LIST  Comma- or space-separated packages to remove
      --dirs LIST      Comma- or space-separated ~/.config entries to remove
  -n, --dry-run        Print what would be removed, then exit
  -h, --help           Show this help and exit

Examples:
  ./uninstall.sh --dry-run --all
  ./uninstall.sh --yes --packages hyprland,waybar --dirs hypr,waybar

NOTE: with --yes every detected backup is restored, without asking.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
    -y | --yes)
        ASSUME_YES=1
        ;;
    --all)
        SELECT_ALL=1
        NONINTERACTIVE=1
        ;;
    --packages)
        shift
        PACKAGES_ARG="${1:-}"
        NONINTERACTIVE=1
        ;;
    --packages=*)
        PACKAGES_ARG="${1#--packages=}"
        NONINTERACTIVE=1
        ;;
    --dirs)
        shift
        DIRS_ARG="${1:-}"
        NONINTERACTIVE=1
        ;;
    --dirs=*)
        DIRS_ARG="${1#--dirs=}"
        NONINTERACTIVE=1
        ;;
    -n | --dry-run)
        DRY_RUN=1
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
done

if [ "$ASSUME_YES" -eq 1 ] && [ "$NONINTERACTIVE" -eq 0 ]; then
    echo "ERROR: --yes also needs --all, --packages and/or --dirs" >&2
    exit 1
fi

printf "\n%.0s" {1..2}
echo -e "\e[35m
	╦╔═┌─┐┌─┐╦    ╦ ╦┬ ┬┌─┐┬─┐┬  ┌─┐┌┐┌┌┬┐
	╠╩╗│ ││ │║    ╠═╣└┬┘├─┘├┬┘│  ├─┤│││ ││ UNINSTALL
	╩ ╩└─┘└─┘╩═╝  ╩ ╩ ┴ ┴  ┴└─┴─┘┴ ┴┘└┘─┴┘ Ubuntu 26.04
\e[0m"
printf "\n%.0s" {1..1}

# Selections go to a private temp dir (never a predictable /tmp path) and are
# removed on exit, including on Ctrl-C
TMP_DIR="$(mktemp -d)" || {
    echo "Failed to create a temp directory"
    exit 1
}
trap 'rm -rf "$TMP_DIR"' EXIT
SELECTED_PACKAGES_FILE="$TMP_DIR/selected_packages.txt"
SELECTED_DIRS_FILE="$TMP_DIR/selected_directories.txt"

# Show welcome message using whiptail with Yes/No options. Skipped whenever the
# run is already scripted (--yes or explicit selections), since whiptail cannot
# even open a terminal in an unattended shell.
if [ "$ASSUME_YES" -eq 0 ] && [ "$NONINTERACTIVE" -eq 0 ]; then
    if ! whiptail --title "Ubuntu 26.04 - KooL Dots Uninstall Script" --yesno \
"Hello! This script will uninstall KooL Hyprland packages and configs.

You can choose packages and directories you want to remove.
NOTE: This will remove configs from ~/.config

WARNING: After uninstallation, your system may become unstable.

Shall we Proceed?" 20 80; then
        echo "$INFO uninstall process canceled."
        exit 0
    fi
fi

# Function to remove selected packages on Debian/Ubuntu
remove_packages() {
    local selected_packages_file=$1
    while read -r package; do
        # Check if the package is installed using dpkg (apt's underlying tool)
        if dpkg -l | grep -q "^ii  $package "; then
            echo "Removing package: $package"
            if ! sudo apt remove -y "$package"; then
                echo "$ERROR Failed to remove package: $package"
            else
                echo "$OK Successfully removed package: $package"
            fi
        else
            echo "$INFO Package ${YELLOW}$package${RESET} not found. Skipping."
        fi
    done < "$selected_packages_file"
}



# Function to restore the backups the installer leaves before it overwrites an
# existing config file:
#   zsh.sh        -> ~/.zshrc-backup, ~/.zprofile-backup (previous shell config)
#   sddm_theme.sh -> /etc/sddm.conf.bak (previous login-screen config)
# Anything else (e.g. the dotfiles' own copy.sh backups) is left untouched.
restore_backups() {
    local restored=0
    local name src dst

    for name in zshrc zprofile; do
        src="$HOME/.${name}-backup"
        dst="$HOME/.${name}"
        [ -f "$src" ] || continue
        if cp "$src" "$dst"; then
            echo "$OK Restored $dst from $src"
            restored=$((restored + 1))
        else
            echo "$ERROR Failed to restore $dst from $src"
        fi
    done

    if [ -f /etc/sddm.conf.bak ]; then
        if sudo cp /etc/sddm.conf.bak /etc/sddm.conf; then
            echo "$OK Restored /etc/sddm.conf from /etc/sddm.conf.bak"
            restored=$((restored + 1))
        else
            echo "$ERROR Failed to restore /etc/sddm.conf from /etc/sddm.conf.bak"
        fi
    fi

    if [ "$restored" -eq 0 ]; then
        echo "$INFO No installer backups found to restore."
    else
        echo "$INFO Restored $restored backup(s)."
    fi
}

# Lists the backups the installer itself leaves behind (used by --dry-run)
installer_backup_list() {
    local name
    for name in zshrc zprofile; do
        [ -f "$HOME/.${name}-backup" ] && printf '%s\n' "$HOME/.${name}-backup"
    done
    [ -f /etc/sddm.conf.bak ] && printf '%s\n' /etc/sddm.conf.bak
    return 0
}

# Function to offer restoring ~/.config backups left by the dotfiles installer.
# The dots' copy.sh lives in another repo, so its suffix is not assumed: every
# common naming style is detected instead.
dotfiles_backup_candidates() {
    local pattern path
    for pattern in "$HOME/.config"/*.bak "$HOME/.config"/*.bak.* \
        "$HOME/.config"/*.old "$HOME/.config"/*-backup "$HOME/.config"/*_backup; do
        for path in $pattern; do
            [ -e "$path" ] && printf '%s\n' "$path"
        done
    done
    return 0
}

# Strip the backup suffix to find the live config a backup belongs to
backup_target() {
    local name
    name="$(basename "$1")"
    name="${name%.bak.*}"
    name="${name%.bak}"
    name="${name%.old}"
    name="${name%-backup}"
    name="${name%_backup}"
    printf '%s/.config/%s\n' "$HOME" "$name"
}

restore_dotfiles_backups() {
    local candidates=() selected=() args=() item target stamp raw

    mapfile -t candidates < <(dotfiles_backup_candidates)
    if [ ${#candidates[@]} -eq 0 ]; then
        echo "$INFO No ~/.config backups found."
        return 0
    fi

    if [ "$ASSUME_YES" -eq 1 ]; then
        selected=("${candidates[@]}")
    else
        for item in "${candidates[@]}"; do
            args+=("$item" "restore over $(basename "$(backup_target "$item")")" "ON")
        done
        if ! raw=$(whiptail --title "Restore ~/.config backups" --checklist \
            "Select the backups to restore over the current config\n\nNOTE: the current entry is kept as <name>.replaced-<timestamp>" \
            25 100 15 "${args[@]}" 3>&1 1>&2 2>&3); then
            echo "$INFO Backup restore skipped."
            return 0
        fi
        mapfile -t selected < <(printf '%s\n' ${raw//\"/})
    fi

    if [ ${#selected[@]} -eq 0 ]; then
        echo "$INFO No backups selected."
        return 0
    fi

    stamp="$(date +%Y%m%d-%H%M%S)"
    for item in "${selected[@]}"; do
        target="$(backup_target "$item")"
        # Never "restore" a path onto itself (happens when no suffix matched)
        [ "$item" = "$target" ] && continue
        if [ -e "$target" ]; then
            if mv "$target" "${target}.replaced-${stamp}"; then
                echo "$INFO Kept current $target as ${target}.replaced-${stamp}"
            else
                echo "$ERROR Could not move $target aside; skipping $item"
                continue
            fi
        fi
        if mv "$item" "$target"; then
            echo "$OK Restored $target from $(basename "$item")"
        else
            echo "$ERROR Failed to restore $target from $item"
        fi
    done
}

# Function to remove selected directories
remove_directories() {
    local selected_dirs_file=$1
    while read -r dir; do
        pattern="$HOME/.config/$dir*"        
        # Loop through directories matching the pattern
        for dir_to_remove in $pattern; do
            if [ -d "$dir_to_remove" ]; then
                echo "Removing directory: $dir_to_remove"
                if ! rm -rf "$dir_to_remove"; then
                    echo "$ERROR Failed to remove directory: $dir_to_remove"
                else
                    echo "$OK Successfully removed directory: $dir_to_remove"
                fi
            else
                echo "$INFO Directory ${YELLOW}$dir_to_remove${RESET} not found. Skipping."
            fi
        done
    done < "$selected_dirs_file"
}

# Define the list of packages to choose from (with options_command tags)
packages=(
    "btop" "resource monitor" "off"
    "brightnessctl" "brightnessctl" "off"
    "cava" "Cross-platform Audio Visualizer" "off"
    "cliphist" "clipboard manager" "off"
    "fastfetch" "fastfetch" "off"
    "ffmpegthumbnailer" "FFmpeg Thumbnailer" "off"
    "grim" "screenshot tool" "off"
    "polkit-kde-agent-1" "polkit agent" "off"
    "imagemagick" "Image manipulation tool" "off"
    "kitty" "kitty-terminal" "off"
    "qt-style-kvantum" "QT apps theming" "off"
    "qt-style-kvantum-themes" "QT apps theming" "off"
    "libqt5quick5" "QT apps theming" "off"
    "libqt5qml5" "QT apps theming" "off"
    "qt6-declarative-dev" "QT apps theming" "off"
    "mousepad" "simple text editor" "off"
    "mpv" "multi-media player" "off"
    "mpv-mpris" "mpv-plugin" "off"
    "nvtop" "gpu resource monitor" "off"
    "nwg-displays" "display monitor configuration app" "off"
    "nwg-look" "gtk settings app" "off"
    "pamixer" "pamixer" "off"
    "pavucontrol" "pavucontrol" "off"
    "playerctl" "playerctl" "off"
    "qalculate-gtk" "calculater - QT" "off"
    "qt5ct" "qt5ct" "off"
    "qt6-svg" "qt6-svg" "off"
    "qt6ct" "qt6ct" "off"
    "slurp" "screenshot tool" "off"
    "swappy" "screenshot tool" "off"
    "sway-notification-center" "notification agent" "off"
    "swww" "wallpaper engine" "off"
    "thunar" "File Manager" "off"
    "thunar-archive-plugin" "Archive Plugin" "off"
    "thunar-volman" "Volume Management" "off"
    "tumbler" "Thumbnail Service" "off"
    "wallust" "color pallete generator" "off"
    "waybar" "wayland bar" "off"
    "wl-clipboard" "clipboard manager" "off"
    "wlogout" "logout menu" "off"
    "xdg-desktop-portal-hyprland" "hyprland file picker" "off"
    "yad" "dialog box" "off"
    "yt-dlp" "video downloader" "off"
    "xarchiver" "Archive Manager" "off"
    "hyprland" "hyprland main package" "off"
    "xfce-polkit" "polkit agent" "off"
)

# Define the list of directories to choose from (with options_command tags)
directories=(
    "ags" "AGS desktop overview configuration" "off"
    "btop" "btop configuration" "off"
    "cava" "cava configuration" "off"
    "fastfetch" "fastfetch configuration" "off"
    "hypr" "main hyprland configuration" "off"
    "kitty" "kitty terminal configuration" "off"
    "Kvantum" "Kvantum-manager configuration" "off"
    "qt5ct" "qt5ct configuration" "off"
    "qt6ct" "qt6ct configuration" "off"
    "rofi" "rofi configuration" "off"
    "swappy" "swappy (screenshot tool) configuration" "off"
    "swaync" "swaync (notification agent) configuration" "off"
    "Thunar" "Thunar file manager configuration" "off"
    "wallust" "wallust (color pallete) configuration" "off"
    "waybar" "waybar configuration" "off"
    "wlogout" "wlogout (logout menu) configuration" "off"    
)

# ─── Selection ──────────────────────────────────────────────────────────────
# Names only, from the whiptail triples (name, description, state)
package_names() { printf '%s\n' "${packages[@]}" | awk 'NR % 3 == 1'; }
directory_names() { printf '%s\n' "${directories[@]}" | awk 'NR % 3 == 1'; }

contains_name() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

validate_names() {
    # $1 = raw list, $2 = label for the error message, rest = known names
    local raw="$1" label="$2" name
    shift 2
    for name in ${raw//,/ }; do
        [ -n "$name" ] || continue
        if ! contains_name "$name" "$@"; then
            echo "Unknown $label: $name" >&2
            exit 1
        fi
    done
}

if [ "$SELECT_ALL" -eq 1 ]; then
    package_names > "$SELECTED_PACKAGES_FILE"
    directory_names > "$SELECTED_DIRS_FILE"
elif [ "$NONINTERACTIVE" -eq 1 ]; then
    : > "$SELECTED_PACKAGES_FILE"
    : > "$SELECTED_DIRS_FILE"
    if [ -n "$PACKAGES_ARG" ]; then
        validate_names "$PACKAGES_ARG" package $(package_names)
        printf '%s\n' ${PACKAGES_ARG//,/ } > "$SELECTED_PACKAGES_FILE"
    fi
    if [ -n "$DIRS_ARG" ]; then
        validate_names "$DIRS_ARG" "~/.config entry" $(directory_names)
        printf '%s\n' ${DIRS_ARG//,/ } > "$SELECTED_DIRS_FILE"
    fi
fi

# Loop for package selection until user selects something or cancels
while [ "$NONINTERACTIVE" -eq 0 ]; do
    package_choices=$(whiptail --title "Select Packages to Uninstall" --checklist \
    "Select the packages you want to remove\nNOTE: 'SPACEBAR' to select & 'TAB' key to change selection" 35 90 25 \
    "${packages[@]}" 3>&1 1>&2 2>&3)

    # Check if the user canceled the operation
    if [ $? -eq 1 ]; then
        echo "$INFO uninstall process canceled."
        exit 0
    fi

    # If no packages are selected, ask again
    if [[ -z "$package_choices" ]]; then
        echo "$NOTE No packages selected. Please select at least one package."
    else
        echo "$package_choices" | tr -d '"' | tr ' ' '\n' > "$SELECTED_PACKAGES_FILE"
        echo "Packages to remove: $package_choices"
        break
    fi
done

# Loop for directory selection until user selects something or cancels
while [ "$NONINTERACTIVE" -eq 0 ]; do
    dir_choices=$(whiptail --title "Select Directories to Remove" --checklist \
    "Select the directories you want to remove\nNOTE: This will remove configs from ~/.config\n\nNOTE: 'SPACEBAR' to select & 'TAB' key to change selection" 28 90 18 \
    "${directories[@]}" 3>&1 1>&2 2>&3)

    # Check if the user canceled the operation
    if [ $? -eq 1 ]; then
        echo "$INFO uninstall process canceled."
        exit 0
    fi

    # If no directories are selected, ask again
    if [[ -z "$dir_choices" ]]; then
        echo "$NOTE No directories selected. Please select at least one directory."
    else
        # Save each selected directory to a new line in the temporary file
        echo "$dir_choices" | tr -d '"' | tr ' ' '\n' > "$SELECTED_DIRS_FILE"
        echo "Directories to remove: $dir_choices"
        break
    fi
done

# First confirmation - Warning about potential instability (skipped with --yes
# and with --dry-run, which must never prompt)
if [ "$ASSUME_YES" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && ! whiptail --title "Warning" --yesno \
"Warning: Removing these packages and directories may cause your system to become unstable and you may not be able to recover it.\n\nAre you sure you want to proceed?" \
10 80; then
    echo "$INFO uninstall process canceled."
    exit 0
fi

# Second confirmation - Final confirmation to proceed (skipped with --yes
# and with --dry-run)
if [ "$ASSUME_YES" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && ! whiptail --title "Final Confirmation" --yesno \
"Are you absolutely sure you want to remove the selected packages and directories?\n\nWARNING! This action is irreversible." \
10 80; then
    echo "$INFO uninstall process canceled."
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo "$NOTE Dry run: nothing will be removed."
    echo "  Packages: $(tr '\n' ' ' < "$SELECTED_PACKAGES_FILE")"
    echo "  Directories: $(tr '\n' ' ' < "$SELECTED_DIRS_FILE")"
    echo "  Installer backups: $(installer_backup_list | tr '\n' ' ')"
    echo "  ~/.config backups: $(dotfiles_backup_candidates | tr '\n' ' ')"
    exit 0
fi

printf "\n%.0s" {1..1}
printf "\n%s${SKY_BLUE}Attempting to remove selected packages${RESET}\n" "${NOTE}"
MAX_ATTEMPTS=2
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Remove packages
    remove_packages "$SELECTED_PACKAGES_FILE"

    # Check if any packages still need to be removed, retry if needed
    MISSING_PACKAGE_COUNT=0
    while read -r package; do
        if dpkg -l | grep -q "^ii  $package "; then
            MISSING_PACKAGE_COUNT=$((MISSING_PACKAGE_COUNT + 1))
        fi
    done < "$SELECTED_PACKAGES_FILE"

    if [ $MISSING_PACKAGE_COUNT -gt 0 ]; then
        ATTEMPT=$((ATTEMPT + 1))
        echo "Attempt #$ATTEMPT failed, retrying..."
    else
        break
    fi
done


printf "\n%.0s" {1..1}
printf "\n%s${SKY_BLUE}Attempting to remove locally installed packages${RESET}\n" "${NOTE}"
for file in ags hypridle hyprlock rofi wallust waybar; do
    if [ -f "/usr/local/bin/$file" ]; then
        sudo rm "/usr/local/bin/$file"
        echo "$file removed."
    fi
done

printf "\n%.0s" {1..1}
printf "\n%s${SKY_BLUE}Attempting to remove selected directories${RESET}\n" "${NOTE}"
remove_directories "$SELECTED_DIRS_FILE"

printf "\n%.0s" {1..1}
printf "\n%s${SKY_BLUE}Attempting to restore installer backups${RESET}\n" "${NOTE}"
restore_backups

printf "\n%.0s" {1..1}
printf "\n%s${SKY_BLUE}Offering to restore ~/.config backups${RESET}\n" "${NOTE}"
restore_dotfiles_backups

printf "\n%.0s" {1..1}
echo -e "$MAGENTA Hyprland and related components have been uninstalled.$RESET"
echo -e "$YELLOW It is recommended to reboot your system now.$RESET"
printf "\n%.0s" {1..1}