#!/usr/bin/env bash
# https://github.com/LinuxBeginnings

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Set a high-contrast whiptail theme unless the user already provided one
if [ -z "${NEWT_COLORS:-}" ]; then
    export NEWT_COLORS='
root=white,black
border=white,black
window=white,black
shadow=black,black
title=yellow,black
button=black,lightgray
actbutton=black,cyan
compactbutton=white,black
textbox=white,black
acttextbox=white,black
entry=white,black
label=white,black
listbox=white,black
actlistbox=black,cyan
checkbox=white,black
actcheckbox=black,cyan
'
fi

# CLI options: Hyprland from the community PPA (default) or the Ubuntu repos
INSTALL_MODE="${INSTALL_MODE:-ppa}"
PRESET_FILE=""
SHOW_HELP=0
while [ $# -gt 0 ]; do
    case "$1" in
    --install-ppa)
        INSTALL_MODE=ppa
        ;;
    --install-ubuntu)
        INSTALL_MODE=ubuntu
        ;;
    --preset)
        shift
        PRESET_FILE="${1:-}"
        if [ -z "$PRESET_FILE" ]; then
            echo "Missing argument for --preset" >&2
            exit 1
        fi
        ;;
    --preset=*)
        PRESET_FILE="${1#--preset=}"
        ;;
    -h | --help)
        SHOW_HELP=1
        ;;
    *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
    shift
done

if [ "$SHOW_HELP" = "1" ]; then
    cat <<USAGE
Usage: ./install.sh [options]

Options:
  --install-ppa       Install Hyprland from the community PPA (default)
  --install-ubuntu    Install Hyprland from the Ubuntu repositories
  --preset FILE       Load option defaults from FILE (see preset.sh)
  -h, --help          Show this help and exit

Notes:
- The community PPA provides the latest Hyprland packages.
- If the PPA path cannot provide Hyprland, the Ubuntu repositories are tried.
- Only Ubuntu 24.04 is supported.
USAGE
    exit 0
fi

case "$INSTALL_MODE" in
ppa | ubuntu) ;;
*)
    echo "Unknown install mode: $INSTALL_MODE (expected ppa or ubuntu)" >&2
    exit 1
    ;;
esac

# Repo root, so the record files do not depend on the caller's working directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colorful text
print_color() {
    printf "%b%s%b\n" "$1" "$2" "$RESET"
}

# Warning: End of Life Support
printf "\n%.0s" {1..2}
print_color $BLUE "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
                 - KooL's UBUNTU 24.04 - 
               Hyprland installed from PPA 
           https://github.com/cppiber/hyprland-ppa   
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    Hyprland version should be current as of the time of this install 
    
"
printf "\n%.0s" {1..2}

# Prompt user to continue or exit
read -rp "$YELLOW Continue with Hyprland installation?  [y/N]: " confirm
case "$confirm" in
[yY][eE][sS] | [yY])
    echo -e "${OK} Continuing with installation..."
    ;;
*)
    echo
    echo
    echo -e "${NOTE} You chose not to continue. Exiting..."
    echo
    exit 1
    ;;
esac

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Start this run with a clean record: the end-of-run summary and
# 03-Final-Check.sh read both files, and the Hyprland source is re-recorded by
# whichever installer script runs.
: >"$REPO_ROOT/Install-Logs/failed-packages.txt"
rm -f "$REPO_ROOT/Install-Logs/hyprland-source.txt"

# Set the name of the log file to include the current date and time
LOG="Install-Logs/01-Hyprland-Install-Scripts-$(date +%d-%H%M%S).log"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
    printf "\n%.0s" {1..2}
    exit 1
fi

# install whiptails if detected not installed. Necessary for this version
if ! command -v whiptail >/dev/null; then
    echo "${NOTE} - whiptail is not installed. Installing..." | tee -a "$LOG"
    sudo apt install -y whiptail
    printf "\n%.0s" {1..1}
fi

printf "\n%.0s" {1..2}
echo -e "\e[35m
	╦╔═┌─┐┌─┐╦    ╦ ╦┬ ┬┌─┐┬─┐┬  ┌─┐┌┐┌┌┬┐
	╠╩╗│ ││ │║    ╠═╣└┬┘├─┘├┬┘│  ├─┤│││ ││ 2025
	╩ ╩└─┘└─┘╩═╝  ╩ ╩ ┴ ┴  ┴└─┴─┘┴ ┴┘└┘─┴┘ Ubuntu 24.04
\e[0m"
printf "\n%.0s" {1..1}

# Welcome message using whiptail (for displaying information)
whiptail --title "KooL Ubuntu 24.04 - Hyprland (2025) Install Script" \
    --msgbox "Welcome to KooL Ubuntu 24.04 - Hyprland (2025) Install Script!!!\n\n\
ATTENTION: Run a full system update and Reboot first !!! (Highly Recommended)\n\n\
NOTE: If you are installing on a VM, ensure to enable 3D acceleration else Hyprland may NOT start!" \
    15 80

# Ask if the user wants to proceed
if ! whiptail --title "Proceed with Installation?" \
    --yesno "Would you like to proceed?" 7 50; then
    echo -e "\n"
    echo "❌ ${INFO} You 🫵 chose ${YELLOW}NOT${RESET} to proceed. ${YELLOW}Exiting...${RESET}" | tee -a "$LOG"
    echo -e "\n"
    exit 1
fi

echo "👌 ${OK} 🇵🇭 ${MAGENTA}KooL..${RESET} ${SKY_BLUE}lets continue with the installation...${RESET}" | tee -a "$LOG"

sleep 1
printf "\n%.0s" {1..1}

# install pciutils if detected not installed. Necessary for detecting GPU
if ! dpkg -l | grep -w pciutils >/dev/null; then
    echo "pciutils is not installed. Installing..." | tee -a "$LOG"
    sudo apt install -y pciutils
    printf "\n%.0s" {1..1}
fi

# Ensure flock (util-linux) is available; required by Hyprland-Dots RofiEmoji.sh
if ! command -v flock >/dev/null 2>&1; then
    echo "${NOTE} - flock (util-linux) is not installed. Installing..." | tee -a "$LOG"
    sudo apt install -y util-linux
    printf "\n%.0s" {1..1}
fi

# Path to the install-scripts directory
script_directory=install-scripts

# Function to execute a script if it exists and make it executable
execute_script() {
    local script="$1"
    local script_path="$script_directory/$script"
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if [ -x "$script_path" ]; then
            bash "$script_path"
            return $?
        else
            echo "Failed to make script '$script' executable." | tee -a "$LOG"
            return 1
        fi
    else
        echo "Script '$script' not found in '$script_directory'." | tee -a "$LOG"
        return 1
    fi
}

# ─── optional components ───────────────────────────────────────────────────
# Optional steps must not abort a nearly finished install, but their failures
# still have to be visible: each one warns, is recorded here, and is repeated by
# 03-Final-Check.sh after the screen is cleared. Kept in its own file because
# update-deps.sh reads the final-check log as a list of missing packages.
failed_optional=()
optional_failures_file="$REPO_ROOT/Install-Logs/optional-failures.txt"
mkdir -p "$(dirname "$optional_failures_file")"
: >"$optional_failures_file"

record_optional_failure() { # record_optional_failure <script>
    mkdir -p "$(dirname "$optional_failures_file")"
    printf '%s\n' "$1" >>"$optional_failures_file"
}

clear_optional_failure() { # clear_optional_failure <script>
    [ -f "$optional_failures_file" ] || return 0
    grep -vxF -- "$1" "$optional_failures_file" >"$optional_failures_file.tmp" || true
    mv "$optional_failures_file.tmp" "$optional_failures_file"
}

run_optional() { # run_optional <script>
    if execute_script "$1"; then
        # A retry that works drops the stale entry from the record.
        clear_optional_failure "$1"
        return 0
    fi
    echo "${WARN} $1 failed; continuing without it (see the log)." | tee -a "$LOG"
    failed_optional+=("$1")
    record_optional_failure "$1"
    return 0
}

# ── install issue summary ─────────────────────────────────────────────
# Everything that did not install: optional components that failed plus any
# package the package steps recorded. The package file is the one the final
# check reads, so this summary matches what the final check would report.
collect_install_issues() {
    install_issues=("${failed_optional[@]}")
    local pkg_file="$REPO_ROOT/Install-Logs/failed-packages.txt"
    if [ -f "$pkg_file" ]; then
        local pkg
        while IFS= read -r pkg; do
            [ -n "$pkg" ] && install_issues+=("package: $pkg")
        done <"$pkg_file"
    fi
    [ ${#install_issues[@]} -gt 0 ]
}

print_install_issues() {
    local issue
    printf "\n${ERROR} Some parts of the install did not complete:\n"
    for issue in "${install_issues[@]}"; do
        printf "  - %s\n" "$issue"
    done
    printf "${NOTE} Logs: %s and %s/Install-Logs/\n" "$LOG" "$REPO_ROOT"
}

# Pauses when something failed, so the user can retry or stop instead of only
# finding out at the very end. Only the optional components can be retried from
# here; package failures need a rerun. ISSUES_ASSUME_TTY=1 lets the tests drive
# the prompt without a terminal.
resolve_install_issues() {
    collect_install_issues || return 0
    print_install_issues
    if [ ! -t 0 ] && [ "${ISSUES_ASSUME_TTY:-0}" != "1" ]; then
        echo "${WARN} Not running interactively; continuing to the final check." | tee -a "$LOG"
        return 0
    fi
    local answer retry script
    while true; do
        printf "\n${CAT} Retry the failed parts (r), continue anyway (c), or abort (a)? "
        read -r answer || answer="a"
        answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
        case "$answer" in
        r | retry)
            if [ ${#failed_optional[@]} -eq 0 ]; then
                echo "${WARN} Only package entries failed; rerun the installer to retry them (see the log)." | tee -a "$LOG"
                continue
            fi
            echo "${INFO} Retrying ${#failed_optional[@]} component(s)..." | tee -a "$LOG"
            retry=("${failed_optional[@]}")
            failed_optional=()
            for script in "${retry[@]}"; do
                run_optional "$script"
            done
            if [ ${#failed_optional[@]} -eq 0 ]; then
                echo "${OK} Retried component(s) installed." | tee -a "$LOG"
                return 0
            fi
            collect_install_issues
            print_install_issues
            ;;
        c | continue | s | skip)
            echo "${WARN} Continuing with the parts that did install." | tee -a "$LOG"
            return 0
            ;;
        a | abort)
            echo "${ERROR} Aborted at your request. Re-run ./install.sh to finish." | tee -a "$LOG"
            exit 1
            ;;
        *)
            echo "${WARN} Please answer r, c or a."
            ;;
        esac
    done
}

# Block unsupported distros for the Hyprland PPA early
if ! execute_script "check-distro-support.sh"; then
    echo "${ERROR} Distro check failed. See above for details." | tee -a "$LOG"
    exit 1
fi

#################
## Default values for the options (overwritten by the preset file when given)
gtk_themes="OFF"
bluetooth="OFF"
thunar="OFF"
ags="OFF"
sddm="OFF"
sddm_themes="OFF"
zsh="OFF"
pokemon="OFF"
rog="OFF"
dots="OFF"
input_group="OFF"
nvidia="OFF"

# Preset files may say Y/N or ON/OFF; whiptail only understands ON/OFF
normalise_state() {
    case "${1:-}" in
    [Yy] | [Yy][Ee][Ss] | ON | on | 1 | true) echo "ON" ;;
    *) echo "OFF" ;;
    esac
}

# Function to load preset file
load_preset() {
    if [ -f "$1" ]; then
        echo "✅ Loading preset: $1"
        # shellcheck disable=SC1090
        source "$1"
        # The preset also sets these defaults, so they reach the checklist below.
        gtk_themes="$(normalise_state "${gtk_themes:-OFF}")"
        bluetooth="$(normalise_state "${bluetooth:-OFF}")"
        thunar="$(normalise_state "${thunar:-OFF}")"
        ags="$(normalise_state "${ags:-OFF}")"
        sddm="$(normalise_state "${sddm:-OFF}")"
        sddm_themes="$(normalise_state "${sddm_themes:-OFF}")"
        zsh="$(normalise_state "${zsh:-OFF}")"
        pokemon="$(normalise_state "${pokemon:-OFF}")"
        rog="$(normalise_state "${rog:-OFF}")"
        dots="$(normalise_state "${dots:-OFF}")"
        input_group="$(normalise_state "${input_group:-OFF}")"
        nvidia="$(normalise_state "${nvidia:-OFF}")"
    else
        echo "⚠️ Preset file not found: $1. Using default values."
    fi
}

# Check if --preset argument is passed
if [ -n "$PRESET_FILE" ]; then
    load_preset "$PRESET_FILE"
fi

# List of services to check for active login managers
services=("gdm.service" "gdm3.service" "lightdm.service" "lxdm.service")

# Function to check if any login services are active
check_services_running() {
    active_services=() # Array to store active services
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            active_services+=("$svc")
        fi
    done

    if [ ${#active_services[@]} -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

if check_services_running; then
    active_list=$(printf "%s\n" "${active_services[@]}")

    # Display the active login manager(s) in the whiptail message box
    whiptail --title "Active non-SDDM login manager(s) detected" \
        --msgbox "The following login manager(s) are active:\n\n$active_list\n\nIf you want to switch login managers, stop and disable the active services above, and reboot before running this script\nRefer to README on switching login managers if needed\n\n- Ja " 24 80
fi

# Check if NVIDIA GPU is detected
nvidia_detected=false
if lspci | grep -i "nvidia" &>/dev/null; then
    nvidia_detected=true
    whiptail --title "NVIDIA GPU Detected" --msgbox "NVIDIA GPU detected in your system.\n\nNOTE: The script will install nvidia drivers via automatic detection if you chose to configure nvidia.\nSee the README" 14 60
fi

# Initialize the options array for whiptail checklist
options_command=(
    whiptail --title "Select Options" --checklist "Choose options to install or configure\nNOTE: spacebar to select" 28 100 20
)

# Add NVIDIA options if detected
if [ "$nvidia_detected" == "true" ]; then
    options_command+=(
        "nvidia" "Do you want script to configure NVIDIA GPU?" "$nvidia"
    )
fi

# Check if user is already in the 'input' group
input_group_detected=false
if ! groups "$(whoami)" | grep -q '\binput\b'; then
    input_group_detected=true
    whiptail --title "Input Group" --msgbox "You are not currently in the input group.\n\nAdding you to the input group might be necessary for the Waybar keyboard-state functionality." 12 60
fi

# Add 'input_group' option if user is not in input group
if [ "$input_group_detected" == "true" ]; then
    options_command+=(
        "input_group" "Add your USER to input group for some waybar functionality?" "$input_group"
    )
fi

# Add the remaining static options
options_command+=(
    "gtk_themes" "Install GTK themes (required for Dark/Light function)" "$gtk_themes"
    "bluetooth" "Do you want script to configure Bluetooth?" "$bluetooth"
    "thunar" "Do you want Thunar file manager to be installed?" "$thunar"
    "ags" "Install AGS v1 for Desktop-Like Overview" "$ags"
    "sddm" "Install and configure SDDM login manager?" "$sddm"
    "sddm_themes" "Install and configure SDDM themes?" "$sddm_themes"
    "zsh" "Install zsh shell with Oh-My-Zsh?" "$zsh"
    "nwg-look" "Install nwg-look for GTK theming? WARNING This Package Takes long time to build!" "OFF"
    "pokemon" "Add Pokemon color scripts to your terminal?" "$pokemon"
    "rog" "Are you installing on Asus ROG laptops?" "$rog"
    "dots" "Download and install pre-configured KooL Hyprland dotfiles?" "$dots"
)

# Capture the selected options before the while loop starts
while true; do
    selected_options=$("${options_command[@]}" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel (exit status 1)
    if [ $? -ne 0 ]; then
        echo -e "\n"
        echo "❌ ${INFO} You 🫵 cancelled the selection. ${YELLOW}Goodbye!${RESET}" | tee -a "$LOG"
        exit 0 # Exit the script if Cancel is pressed
    fi

    # If no option was selected, notify and restart the selection
    if [ -z "$selected_options" ]; then
        whiptail --title "Warning" --msgbox "No options were selected. Please select at least one option." 10 60
        continue # Return to selection if no options selected
    fi

    # Strip the quotes and trim spaces if necessary (sanitize the input)
    selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

    # Convert selected options into an array (preserving spaces in values)
    IFS=' ' read -r -a options <<<"$selected_options"

    # Check if the "dots" option was selected
    dots_selected="OFF"
    for option in "${options[@]}"; do
        if [[ "$option" == "dots" ]]; then
            dots_selected="ON"
            break
        fi
    done

    # If "dots" is not selected, show a note and ask the user to proceed or return to choices
    if [[ "$dots_selected" == "OFF" ]]; then
        # Show a note about not selecting the "dots" option
        if ! whiptail --title "KooL Hyprland Dot Files" --yesno \
            "You have not selected to install the pre-configured KooL Hyprland dotfiles.\n\nKindly NOTE that if you proceed without Dots, Hyprland will start with default vanilla Hyprland configuration and I won't be able to give you support.\n\nWould you like to continue install without KooL Hyprland Dots or return to choices/options?" \
            --yes-button "Continue" --no-button "Return" 15 90; then
            echo "🔙 Returning to options..." | tee -a "$LOG"
            continue
        else
            # User chose to continue
            echo "${INFO} ⚠️ Continuing WITHOUT the dotfiles installation..." | tee -a "$LOG"
            printf "\n%.0s" {1..1}
        fi
    fi

    # Prepare the confirmation message
    confirm_message="You have selected the following options:\n\n"
    for option in "${options[@]}"; do
        confirm_message+=" - $option\n"
    done
    confirm_message+="\nAre you happy with these choices?"

    # Confirmation prompt
    if ! whiptail --title "Confirm Your Choices" --yesno "$(printf "%s" "$confirm_message")" 25 80; then
        echo -e "\n"
        echo "❌ ${SKY_BLUE}You're not 🫵 happy${RESET}. ${YELLOW}Returning to options...${RESET}" | tee -a "$LOG"
        continue
    fi

    echo "👌 ${OK} You confirmed your choices. Proceeding with ${SKY_BLUE}KooL 🇵🇭 Hyprland Installation...${RESET}" | tee -a "$LOG"
    break
done

printf "\n%.0s" {1..1}

echo "${INFO} Running a ${SKY_BLUE}full system update...${RESET}" | tee -a "$LOG"
sudo apt update

# Install the Hyprland stack early (ensures newer versions like Waybar). The PPA
# is the default path; when it cannot provide Hyprland on this release the
# Ubuntu repositories are tried before giving up.
case "$INSTALL_MODE" in
ppa)
    export HYPR_USE_PPA=1
    if ! execute_script "hyprland-ppa.sh"; then
        echo "${WARN} The community PPA did not provide Hyprland; trying the Ubuntu repositories." | tee -a "$LOG"
        if ! execute_script "hyprland-ubuntu.sh"; then
            echo "${ERROR} Hyprland could not be installed from the PPA or the Ubuntu repositories." | tee -a "$LOG"
            exit 1
        fi
    fi
    ;;
ubuntu)
    export HYPR_USE_PPA=0
    if ! execute_script "hyprland-ubuntu.sh"; then
        echo "${ERROR} Hyprland could not be installed from the Ubuntu repositories." | tee -a "$LOG"
        exit 1
    fi
    ;;
esac

echo "${INFO} Installing ${SKY_BLUE}necessary dependencies...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "00-dependencies.sh" | tee -a "$LOG" || {
    echo "${ERROR:-[ERROR]} Dependencies installation failed" | tee -a "$LOG"
    exit 1
}

echo "${INFO} Installing ${SKY_BLUE}necessary fonts...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "fonts.sh" || {
    echo "${ERROR:-[ERROR]} Fonts installation failed" | tee -a "$LOG"
    exit 1
}

echo "${INFO} Installing ${SKY_BLUE}KooL Hyprland packages (via PPA)...${RESET}" | tee -a "$LOG"
sleep 1
# Install remaining desktop packages from Ubuntu repos/PPAs
execute_script "01-hypr-pkgs.sh" || {
    echo "${ERROR:-[ERROR]} Hyprland packages installation failed" | tee -a "$LOG"
    exit 1
}
sleep 1
run_optional "wallust.sh"
sleep 1
run_optional "swappy.sh"
sleep 1
run_optional "swww.sh"
sleep 1
run_optional "rofi-wayland.sh"
sleep 1
run_optional "nwg-displays.sh"
sleep 1
run_optional "hyprlock.sh"
sleep 1
run_optional "hypridle.sh"
sleep 1
run_optional "yazi.sh"

sleep 1
echo "${INFO} Building and installing ${SKY_BLUE}Waybar from source${RESET} (required for Hyprland Lua workflow)..." | tee -a "$LOG"
execute_script "waybar.sh" || {
    echo "${ERROR:-[ERROR]} Waybar build failed" | tee -a "$LOG"
    exit 1
}

sleep 1
# Clean up the selected options (remove quotes and trim spaces)
selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

# Convert selected options into an array (splitting by spaces)
IFS=' ' read -r -a options <<<"$selected_options"

# Loop through selected options
for option in "${options[@]}"; do
    case "$option" in
    nvidia)
        echo "${INFO}Configuring ${SKY_BLUE}nvidia stuff${RESET}" | tee -a "$LOG"
        run_optional "nvidia.sh"
        ;;
    gtk_themes)
        echo "${INFO}Installing ${SKY_BLUE}GTK themes...${RESET}" | tee -a "$LOG"
        run_optional "gtk_themes.sh"
        ;;
    input_group)
        echo "${INFO}Adding user into ${SKY_BLUE}input group...${RESET}" | tee -a "$LOG"
        run_optional "InputGroup.sh"
        ;;
    ags)
        echo "${INFO}Installing ${SKY_BLUE}AGS v1 for Desktop Overview...${RESET}" | tee -a "$LOG"
        run_optional "ags.sh"
        ;;
    sddm)
        echo "${INFO}Installing and configuring ${SKY_BLUE}SDDM...${RESET}" | tee -a "$LOG"
        run_optional "sddm.sh"
        ;;
    sddm_themes)
        echo "${INFO}Installing and configuring ${SKY_BLUE}SDDM themes...${RESET}" | tee -a "$LOG"
        run_optional "sddm_theme.sh"
        ;;
    bluetooth)
        echo "${INFO}Configuring ${SKY_BLUE}Bluetooth...${RESET}" | tee -a "$LOG"
        run_optional "bluetooth.sh"
        ;;
    thunar)
        echo "${INFO}Installing ${SKY_BLUE}Thunar file manager...${RESET}" | tee -a "$LOG"
        run_optional "thunar.sh"
        run_optional "thunar_default.sh"
        ;;
    zsh)
        echo "${INFO}Installing ${SKY_BLUE}zsh with Oh-My-Zsh...${RESET}" | tee -a "$LOG"
        run_optional "zsh.sh"
        ;;
    nwg-look)
        echo "${INFO}Installing ${SKY_BLUE}nwg-look...${RESET}" | tee -a "$LOG"
        run_optional "nwg-look.sh"
        ;;
    pokemon)
        echo "${INFO}Adding ${SKY_BLUE}Pokemon color scripts to terminal...${RESET}" | tee -a "$LOG"
        run_optional "zsh_pokemon.sh"
        ;;
    rog)
        echo "${INFO}Installing ${SKY_BLUE}ROG laptop packages...${RESET}" | tee -a "$LOG"
        run_optional "rog.sh"
        ;;
    dots)
        # The dots installer takes over the screen, so any earlier failure gets
        # one chance to be retried or to stop the run first.
        resolve_install_issues
        echo "${INFO}Installing pre-configured ${SKY_BLUE}KooL Hyprland dotfiles...${RESET}" | tee -a "$LOG"
        run_optional "dotfiles.sh"
        ;;
    *)
        echo "Unknown option: $option" | tee -a "$LOG"
        ;;
    esac
done

# Perform cleanup
# Everything has been installed by now: surface failures once, with a chance to
# retry, before the screen is cleared for the final check and the reboot prompt.
resolve_install_issues

printf "\n${OK} Performing some clean up.\n"
files_to_delete=("JetBrainsMono.tar.xz" "VictorMonoAll.zip" "FantasqueSansMono.zip")
for file in "${files_to_delete[@]}"; do
    if [ -e "$file" ]; then
        echo "$file found. Deleting..." | tee -a "$LOG"
        rm "$file"
        echo "$file deleted successfully." | tee -a "$LOG"
    fi
done

clear

printf "\n%.0s" {1..2}
# final check essential packages if it is installed
execute_script "03-Final-Check.sh"

printf "\n%.0s" {1..1}

# Check if Hyprland is installed via PATH or dpkg (covers PPA installs)
if command -v hyprland >/dev/null 2>&1 || dpkg -l | grep -q "^ii  hyprland "; then
    printf "\n ${OK} 👌 Hyprland is installed. However, some essential packages may not be installed. Please see above!"
    printf "\n${CAT} Ignore this message if it states ${YELLOW}All essential packages${RESET} are installed as per above\n"
    sleep 2
    printf "\n%.0s" {1..2}

    printf "${SKY_BLUE}Thank you${RESET} 🫰 for using 🇵🇭 ${MAGENTA}KooL's Hyprland Dots${RESET}. ${YELLOW}Enjoy and Have a good day!${RESET}"
    printf "\n%.0s" {1..2}

    printf "\n${NOTE} You can start Hyprland by typing ${SKY_BLUE}Hyprland${RESET} (IF SDDM is not installed) (note the capital H!).\n"
    printf "\n${NOTE} However, it is ${YELLOW}highly recommended to reboot${RESET} your system.\n\n"

    while true; do
        echo -n "${CAT} Would you like to reboot now? (y/n): "
        read HYP
        HYP=$(echo "$HYP" | tr '[:upper:]' '[:lower:]')

        if [[ "$HYP" == "y" || "$HYP" == "yes" ]]; then
            echo "${INFO} Rebooting now..."
            systemctl reboot
            break
        elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
            echo "👌 ${OK} You chose NOT to reboot"
            printf "\n%.0s" {1..1}
            # Check if NVIDIA GPU is present
            if lspci | grep -i "nvidia" &>/dev/null; then
                echo "${INFO} HOWEVER ${YELLOW}NVIDIA GPU${RESET} detected. Reminder that you must REBOOT your SYSTEM..."
                printf "\n%.0s" {1..1}
            fi
            break
        else
            echo "${WARN} Invalid response. Please answer with 'y' or 'n'."
        fi
    done
else
    # Print error message if Hyprland not found
    printf "\n${WARN} Hyprland is NOT installed. Please check 00_CHECK-time_installed.log and other files in the Install-Logs/ directory..."
    printf "\n%.0s" {1..3}
    exit 1
fi

printf "\n%.0s" {1..2}
