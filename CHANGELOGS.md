## CHANGELOGS

## Aug 2026

 - Added:
   - `install-scripts/waybar.sh` to build waybar from source (matches Debian)
 - Changed:
   - `waybar` removed from APT package list (`01-hypr-pkgs.sh`); now purges any APT
     package and builds from source only — prevents apt upgrades from silently
     overriding the source-built binary

## Jul 2026

- Updated:
    - `swww.sh` to clone / install `awww`
        - `swww` has been renamed to `awww`

## May 2026

- Fixed:
    - Linux Mint ID breaks `yazi.sh`
        - Now checks for `UNBUNTU_CODENAME` as backup
    - Some scripts not executable
    - `libdisplay-info3` for 26.04
    - Link in `README.md`
    - Set dark theme for whiptail fixes colors washed out on some terminals
        - Removed some duplicate colors
        - Fixed hight on OK/Cancel button
    - `auto-install.sh`
        - The script would got a git pull if Distro-Hyprland directory exsited
        - If user started with JakooLit installer it would not get updated code
        - Changed to remove `Distro-Hyprland` and do fresh git clone

- Added:
    - New GH repo for `yazi`
        - `dariogriffo/yazi-debian`
        - Up to date and has deb pkgs for all debian and ubuntu versions
        - Kept the original debian only repo as backup
        - Checks for old versions of `yazi` removes if found
    - CLI File manager `yazi`
    - `update-deps.sh` Install new dependencies since last install
        - You don't have to re-install everything, verifies you have all new deps
        - If not it will install them
    - `ddcutil` to support external monitor brightness
    - `socat` to fix `Tak0` scripts
    - `stylua` COPR for LUA support
- Removed hyprland-qtutils not used anymore
- Fixed `quickshell.sh` Missing `cpptrace` and other deps
- Disabled `hyprland-qtuils` it's no longer used
- Removed duplicate `hyprland-guituils`

## Apr 2026

- Fixed: `install.sh` set color to dark contrast for readability
- Fixed: `install.sh` was overwritting fastfetch config
- Fixed: Polkit issue
    - Added missing QT kvantum pkgs

```bash
  sudo apt install libqt5quick5 libqt5qml5 qt6-declarative-dev
```

- Improved: Error handling in the `install.sh` script
    - Thank you `@moukhtar22` for finding this and filing an issue
- Removed incorrect `qt` packages
    - Thank you `@moukhtar22` for finding this and filing an issue

## Mar 2026

- Added rofi version/presence check
- Manually Added Hyprland PPA for testing
    - When ubuntu v26.04 is released the PPA repo will add support
- Added `hyprland-guituils` to dependencies
- Removed Jak ko-fi, stars from README
- Updated `swww` to v0.11.2
- Added version checks for `wallust` and `rust` to prevent re-installation
- Updtated discord links
- Added Spanish Translations
- Added `go`
    - To build `nwg-drawer` and `dock-hyprland`
- Fixed flatpak install
- Installed `gum` from snap
- Added missing dependencies for `quickshell`
    - Created document on how to build `quickshell`
    - Lists packages, scripts and common errors

## Dec 2025

- Started work on supporting ubuntu 26.04
    - Hyprland packages for 0.52.2 are in repo
    - rofi w/wayland support is in repo
    - install script will remove PPA based packages

## Oct 2025

- Added PPA to install Hyprland from packages
- https://github.com/cpiber/hyprland-ppa
- No more building from source - but it remains a fallback option
- Updated Hyprland packages should not be installed during normal updates

## Sep 2025

- New life for ubuntu 25.10+
- For Ubuntu 25.10+ we can build Hyprland from source

## 08 June 2025

- updated SDDM theme.

## 20 March 2025

- added findutils as dependencies

## 11 March 2025

- Added uninstall script
- forked AGS v1 into JakooLit repo. This is just incase Aylur decide to take down v1

## 06 March 2025

- Switched to whiptail version for Y & N questions
- switched eza to lsd

## 23 Feb 2025

- added Victor Mono Font for proper hyprlock font rendering for Dots v2.3.12
- added Fantasque Sans Mono Nerd for Kitty

## 22 Feb 2025

- replaced eog with loupe
- changed url for installing oh-my-zsh to get wider coverage. Some countries are blocking github raw url's

## 20 Feb 2025

- Added nwg-displays for the upcoming Kools dots v2.3.12

## 18 Feb 2025

- Change default zsh theme to adnosterzak
- pokemon coloscript integrated with fastfetch when opted with pokemon to add some bling
- additional external oh-my-zsh theme

## 06 Feb 2025

- added semi-unattended function.
- move all the initial questions at the beginning

## 04 Feb 2025

- Re-coded for better visibility
- Offered a new SDDM theme.
- script will automatically detect if you have nvidia but script still offer if you want to set up for user

## 04 Feb 2025

- offering a new SDDM theme from here [SDDM](https://codeberg.org/minMelody/sddm-sequoia)
- some tweaking on install-scripts except the compiling part. It will not show progress for much cleaner work
- script will automatically detect if you have nvidia but script still offer if you want to set up for user

## 30 Jan 2025

- AGS (aylur's GTK shell) v1 for desktop overview is now optional

## 12 Jan 2025

- switch to final version of aylurs-gtk-shell-v1

## 07 Jan 2025

- added fastfetch for Ubuntu
- default oh-my-zsh theme was changed to `funky`

## 01 Jan 2025

- Switched to download dots from KooL's Hyprland dots specific branch

## 26 Dec 2024

- New Repo
- New Branch for Ubuntu 25.04
- xdph is installing on universe branch
