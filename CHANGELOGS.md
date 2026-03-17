<<<<<<< HEAD
## CHANGELOGS

## March 2026

- PPA Hyprland updted to v0.54.2
- Added `rsync` check
- Added `rofi-wayland` check for ubuntu v24.04 repo not uddate yet to v2.00

## December 2025

- Ubuntu 24.04 supports Hyprland v0.53.1

## October 2025

- Moved to PPA to install current Hyprland version
- https://github.com/cppiber/hyprland-ppa
- Current Hyprland Dotfiles are now supported
- Updated SWWW to v0.11.2

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
- added nwg-displays to install

## 22 Feb 2025

- replaced eog with loupe
- changed url for installing oh-my-zsh to get wider coverage. Some countries are blocking github raw url's

## 18 Feb 2025

- Change default zsh theme to adnosterzak
- pokemon coloscript integrated with fastfetch when opted with pokemon to add some bling
- additional external oh-my-zsh theme## 18 Feb 2025

## 06 Feb 2025

- added semi-unattended function.
- move all the initial questions at the beginning

## 04 Feb 2025

- Re-coded for better visibility
- script will automatically detect if you have nvidia but script still offer if you want to set up for use

## 30 Jan 2025

- AGS v1 installation is now optional.
- switched to a specific branch on KooL's Hyprland-Dots to make it easier to update

## 12 Jan 2025

- switch to final version of aylurs-gtk-shell-v1

## 07 Jan 2025

- added fastfetch for Ubuntu
- default oh-my-zsh theme was changed to `funky`

## 26 Dec 2024

- Removal of Bibata Ice cursor on assets since its integrated in the GTK Themes and Icons extract from a separate repo

## 17 Dec 2024

- updated link for swww.sh

## 10 Dec 2024

- updated swww.sh to download from version v0.9.5

## 20 Nov 2024

- switched to download rofi-wayland from releases instead from upstream

## 20 Sep 2024

- User will be ask if they want to set Thunar as default file manager if they decided to install it

## 14 Sep 2024

- Added Essential Packages final check in lieu of errors from Install log files in Install-Logs directory

## 10 Sep 2024

- added background check of known login managers if they are active if user chose to install sddm

## 08 Sep 2024

- Added final error checks on install-logs

## 07 Sep 2024

- disabled imagemagick compilation from source
- dotfiles adjusted so it will be compatible for imagemagick v6

## 25 Aug 2024

- a bit of refactored tailored into "newer" Hyprland dots
- wallust will be installed using cargo
- code clean up
||||||| 814e28a
## Changelogs
=======
## CHANGELOGS
>>>>>>> 25.10-development

<<<<<<< HEAD
## 11 June 2024

- adjusted script to install only Hyprland-Dots v2.2.14
||||||| 814e28a
## 11 June 2024
- adjusted script to install only Hyprland-Dots v2.2.14
=======
## Mar 2026
>>>>>>> 25.10-development

<<<<<<< HEAD
## 10 June 2024

- changed behaviour of rofi-wayland.sh. To redownload a new rofi-wayland from repo instead of pulling changes. (It proves giving issue)
||||||| 814e28a
## 10 June 2024
- changed behaviour of rofi-wayland.sh. To redownload a new rofi-wayland from repo instead of pulling changes. (It proves giving issue)
=======
- PPA updated to Hyprland v0.54.2
- Added check for `rofi` it was begin removed
    - Script was trying to install `rofi-wayland`
    - Package no longer exists
    - Now checks for rofi installed and correct version
>>>>>>> 25.10-development

<<<<<<< HEAD
## 04 June 2024

- switched over to source install for imagemagick
- removal of fzf for Debian and Ubuntu (headache)
||||||| 814e28a
## 04 June 2024
- switched over to source install for imagemagick
- removal of fzf for Debian and Ubuntu (headache)
=======
## Oct 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 26 May 2024

- Added fzf for zsh (CTRL R to invoke FZF history)
||||||| 814e28a
## 26 May 2024
- Added fzf for zsh (CTRL R to invoke FZF history)
=======
- Added PPA to install Hyprland from packages
- https://github.com/cpiber/hyprland-ppa
- No more building from source - but it remains a fallback option
- Updated Hyprland packages should not be installed during normal updates
>>>>>>> 25.10-development

<<<<<<< HEAD
## 23 May 2024

- added qalculate-gtk to work with rofi-calc. Default keybinds (SUPER ALT C)
- added power-profiles-daemon for ROG laptops. Note, I cant add to all since it conflicts with TLP, CPU-Auto-frequency etc.
- Note: Fastfetch configs will be added from Hyprland-Dots v2.2.12. However, you need to install from Fastfetch github page
||||||| 814e28a
## 23 May 2024
- added qalculate-gtk to work with rofi-calc. Default keybinds (SUPER ALT C)
- added power-profiles-daemon for ROG laptops. Note, I cant add to all since it conflicts with TLP, CPU-Auto-frequency etc.
- Note: Fastfetch configs will be added from Hyprland-Dots v2.2.12. However, you need to install from Fastfetch github page
=======
## Sep 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 22 May 2024

- change the sddm theme destination to /etc/sddm.conf.d/10-theme.conf to theme.conf.user
||||||| 814e28a
## 22 May 2024
- change the sddm theme destination to /etc/sddm.conf.d/10-theme.conf to theme.conf.user
=======
- New life for ubuntu 25.10+
- For Ubuntu 25.10+ we can build Hyprland from source
>>>>>>> 25.10-development

<<<<<<< HEAD
## 19 May 2024

- Disabled the auto-login in .zprofile as it causes auto-login to Hyprland if any wayland was chosen. Can enabled if only using hyprland
||||||| 814e28a
## 19 May 2024
- Disabled the auto-login in .zprofile as it causes auto-login to Hyprland if any wayland was chosen. Can enabled if only using hyprland
=======
## 08 June 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 10 May 2024

- added wallust-git and remove python-pywal for migration to wallust on Hyprland-Dots v2.2.11
||||||| 814e28a
## 10 May 2024
- added wallust-git and remove python-pywal for migration to wallust on Hyprland-Dots v2.2.11
=======
- updated SDDM theme.
>>>>>>> 25.10-development

<<<<<<< HEAD
## 07 May 2024

- added ags.sh for upcoming ags overview for next Hyprland-Dots release. Will be installed form source
||||||| 814e28a
## 07 May 2024
- added ags.sh for upcoming ags overview for next Hyprland-Dots release. Will be installed form source
=======
## 20 March 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 03 May 2024

- Bump swww to v0.9.5
- added python3-pyquery for new weather-waybar python based on Hyprland-Dots
||||||| 814e28a
## 03 May 2024
- Bump swww to v0.9.5
- added python3-pyquery for new weather-waybar python based on Hyprland-Dots
=======
- added findutils as dependencies
>>>>>>> 25.10-development

<<<<<<< HEAD
## 03 May 2024

- Bump swww to v0.9.5
- added python3-pyquery for new weather-waybar python based on Hyprland-Dots
||||||| 814e28a
## 03 May 2024
- Bump swww to v0.9.5
- added python3-pyquery for new weather-waybar python based on Hyprland-Dots
=======
## 11 March 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 02 May 2024

- Added pyprland (hyprland plugin) - warning, I cant make it to properly run. Drop Down terminal not working, zoom is hit and miss
||||||| 814e28a
## 02 May 2024
- Added pyprland (hyprland plugin) - warning, I cant make it to properly run. Drop Down terminal not working, zoom is hit and miss
=======
- Added uninstall script
- forked AGS v1 into JakooLit repo. This is just incase Aylur decide to take down v1
>>>>>>> 25.10-development

<<<<<<< HEAD
## 30 Apr 2024

- Updated hyprland.sh to install v0.39.1 Hyprland
- adding hypridle and hyprlock
- dropping swaylock-effects and swayidle
- adjusted to work with current Hyprland-Dots
||||||| 814e28a
## 30 Apr 2024
- Updated hyprland.sh to install v0.39.1 Hyprland
- adding hypridle and hyprlock
- dropping swaylock-effects and swayidle
- adjusted to work with current Hyprland-Dots
=======
## 06 March 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 22 Apr 2024

- Change dotfiles to specific version only as Debian and Ubuntu cant keep up with Hyprland development
||||||| 814e28a
## 22 Apr 2024
- Change dotfiles to specific version only as Debian and Ubuntu cant keep up with Hyprland development
=======
- Switched to whiptail version for Y & N questions
- switched eza to lsd
>>>>>>> 25.10-development

<<<<<<< HEAD
## 20 Apr 2024

- Change default Oh-my-zsh theme to xiong-chiamiov-plus
||||||| 814e28a
## 20 Apr 2024
- Change default Oh-my-zsh theme to xiong-chiamiov-plus
=======
## 23 Feb 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 11 Jan 2024

- dropped wlsunset
- added hyprlang build and install
||||||| 814e28a
## 11 Jan 2024
- dropped wlsunset
- added hyprlang build and install
=======
- added Victor Mono Font for proper hyprlock font rendering for Dots v2.3.12
- added Fantasque Sans Mono Nerd for Kitty
>>>>>>> 25.10-development

<<<<<<< HEAD
## 02 Jan 2024

- Readme updated for cliphist instruction for ubuntu 23.10 users
- Created cliphist.sh for ubuntu 23.10 users (disabled by default and needs to be enabled on install.sh if desired)
||||||| 814e28a
## 02 Jan 2024
- Readme updated for cliphist instruction for ubuntu 23.10 users
- Created cliphist.sh for ubuntu 23.10 users (disabled by default and needs to be enabled on install.sh if desired)
=======
## 22 Feb 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 30 December 2023

- Code Cleaned up.
- Pokemon Color Scripts now offered as optional
||||||| 814e28a
## 30 December 2023
- Code Cleaned up.
- Pokemon Color Scripts now offered as optional
=======
- replaced eog with loupe
- changed url for installing oh-my-zsh to get wider coverage. Some countries are blocking github raw url's
>>>>>>> 25.10-development

<<<<<<< HEAD
## 29 December 2023

- Remove dunst in favor of swaync. NOTE: Part of the script is to also uninstall mako and dunst (if installed) as on my experience, dunst is sometimes taking over the notification even if it is not set to start
||||||| 814e28a
## 29 December 2023
- Remove dunst in favor of swaync. NOTE: Part of the script is to also uninstall mako and dunst (if installed) as on my experience, dunst is sometimes taking over the notification even if it is not set to start
=======
## 20 Feb 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 16 Dec 2023

- zsh theme switched to `agnoster` theme by default
- pywal tty color change disabled by default
||||||| 814e28a
## 16 Dec 2023
- zsh theme switched to `agnoster` theme by default
- pywal tty color change disabled by default
=======
- Added nwg-displays for the upcoming Kools dots v2.3.12
>>>>>>> 25.10-development

<<<<<<< HEAD
## 13 Dec 2023

- Added a script / function to force install packages. Some users reported that it is not installed.
||||||| 814e28a
## 13 Dec 2023
- Added a script / function to force install packages. Some users reported that it is not installed.
=======
## 18 Feb 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 11 Dec 2023

- Changing over to zsh automatically if user opted
- If chose to install zsh and have no login manager, zsh auto login will auto start Hyprland
- added as optional, with zsh, pokemon colorscripts
- improved zsh install scripts, so even the existing zsh users of can still opt for zsh and oh-my-zsh installation :)
||||||| 814e28a
## 11 Dec 2023
- Changing over to zsh automatically if user opted
- If chose to install zsh and have no login manager, zsh auto login will auto start Hyprland
- added as optional, with zsh, pokemon colorscripts
- improved zsh install scripts, so even the existing zsh users of can still opt for zsh and oh-my-zsh installation :)
=======
- Change default zsh theme to adnosterzak
- pokemon coloscript integrated with fastfetch when opted with pokemon to add some bling
- additional external oh-my-zsh theme
>>>>>>> 25.10-development

<<<<<<< HEAD
## 03 Dec 2023

- Added kvantum for qt apps theming
- return of wlogout due to theming issues of rofi-power
||||||| 814e28a
## 03 Dec 2023
- Added kvantum for qt apps theming
- return of wlogout due to theming issues of rofi-power
=======
## 06 Feb 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 1 Dec 2023

- replace the Hyprland to specific branch/version as newest needed some new libraries and debian dont have those yet
||||||| 814e28a
## 1 Dec 2023
- replace the Hyprland to specific branch/version as newest needed some new libraries and debian dont have those yet
=======
- added semi-unattended function.
- move all the initial questions at the beginning
>>>>>>> 25.10-development

<<<<<<< HEAD
## 26 Nov 2023

- nvidia - Move to normal hyprland package as nvidia patches are doing nothing see [`commit`](https://github.com/hyprwm/Hyprland/commit/cd96ceecc551c25631783499bd92c6662c5d3616)
||||||| 814e28a
## 26 Nov 2023
- nvidia - Move to normal hyprland package as nvidia patches are doing nothing see [`commit`](https://github.com/hyprwm/Hyprland/commit/cd96ceecc551c25631783499bd92c6662c5d3616)
=======
## 04 Feb 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 25 Nov 2023

- drop wlogout since Hyprland-Dots v2.1.9 uses rofi-power
||||||| 814e28a
## 25 Nov 2023
- drop wlogout since Hyprland-Dots v2.1.9 uses rofi-power
=======
- Re-coded for better visibility
- Offered a new SDDM theme.
- script will automatically detect if you have nvidia but script still offer if you want to set up for user
>>>>>>> 25.10-development

<<<<<<< HEAD
## 23-Nov-2023

- Added Bibata cursor to install if opted for GTK Themes. However, it is not pre-applied. Use nwg-look utility to apply
||||||| 814e28a
## 23-Nov-2023
- Added Bibata cursor to install if opted for GTK Themes. However, it is not pre-applied. Use nwg-look utility to apply
=======
## 04 Feb 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 19-Nov-2023

- Adjust dotfiles script to download from releases instead of from upstream
||||||| 814e28a
## 19-Nov-2023
- Adjust dotfiles script to download from releases instead of from upstream
=======
- offering a new SDDM theme from here [SDDM](https://codeberg.org/minMelody/sddm-sequoia)
- some tweaking on install-scripts except the compiling part. It will not show progress for much cleaner work
- script will automatically detect if you have nvidia but script still offer if you want to set up for user
>>>>>>> 25.10-development

<<<<<<< HEAD
## 14-Oct-2023

- initial release. Added swappy for screenshots
||||||| 814e28a
## 14-Oct-2023
- initial release. Added swappy for screenshots
=======
## 30 Jan 2025
>>>>>>> 25.10-development

<<<<<<< HEAD
## 12-Oct-2023

- BETA release
||||||| 814e28a
## 12-Oct-2023
- BETA release
=======
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
>>>>>>> 25.10-development
