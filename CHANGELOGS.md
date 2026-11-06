## CHANGELOGS

## Nov 2026

- Added:
    - `install-scripts/packages.sh` as the single package manifest: `01-hypr-pkgs.sh`
      installs from it and `03-Final-Check.sh` verifies every required entry, so the
      two lists can no longer drift apart
    - `network-manager` to default package dependencies (`01-hypr-pkgs.sh`) and to
      the `03-Final-Check.sh` verification list. Only the `nm-tray` applet was
      installed before, so a minimal install had no NetworkManager daemon or
      `nmcli`
    - Quickshell minimum version check (`0.3.0`) to `quickshell.sh`,
      `03-Final-Check.sh`, and `update-deps.sh`
    - `install-scripts/Global_versions.sh` as the single place for that minimum
      and the shared version helpers
    - `WAYBAR_MIN_VERSION` (`0.15.0-1100-gf6f73c81`) and the `hypridle`/`hyprlock`
      minimums (`0.1.6` / `0.9.1`) to `Global_versions.sh`, with shared binary
      version helpers
    - `tests/uninstall-test.sh`, which checks the `~/.config` backup detection and
      the uninstall option parsing against a throwaway `HOME` (no sudo, no system
      changes)
    - `tests/run-all.sh` to run the suite (it also runs shellcheck and fails on
      any finding), plus `tests/apt-candidate-test.sh` (APT candidate lookup
      under a non-English locale, stubbed `apt-cache`), `tests/ppa-series-test.sh`
      (PPA series guard against fixture APT sources), `tests/install-dry-run-test.sh`
      (the `--dry-run` PPA verdict, and that a dry run writes nothing),
      `tests/hyprland-ppa-test.sh` (the PPA script's four outcomes via stubbed
      `sudo`/`apt`), `tests/install-fallback-test.sh` (the `ppa)` branch's
      fallback wiring), `tests/update-deps-summary-test.sh` (the summary's
      missing-package parsing and Hyprland state) and
      `tests/final-check-summary-test.sh` (the final check's Hyprland source
      lines and optional-component summary, per recorded outcome) and
      `tests/optional-scripts-test.sh` (failing optional components, the
      retry/continue/abort prompt including on a pty, and the early
      install-mode guard)
    - `ubuntu_codename`, `ppa_suites`, `ppa_series_ok` and the Hyprland source
      record helpers to `install-scripts/Global_functions.sh`, so `install.sh`,
      `hyprland-ppa.sh`, `hyprland-ubuntu.sh`, `update-deps.sh` and
      `03-Final-Check.sh` share them
    - `03-Final-Check.sh` reports whether Hyprland came from the community PPA or
      the Ubuntu repositories, and why the PPA path was not used
    - `install-scripts/install-hyprmod.sh`, which installs the HyprMod
      GTK4/libadwaita settings app through its upstream installer, and installs
      the packages it needs first: GTK4/libadwaita, their
      `gir1.2-gtk-4.0`/`gir1.2-adw-1` typelibs (without them `python3-gi` cannot
      import either), `pipx`, and the PyGObject build dependencies - PyGObject
      publishes no Python 3.14 wheels, so it is compiled in the tool's virtualenv
    - `install.sh` runs that HyprMod script as an optional component, so a
      failure warns and the install carries on
- Changed:
    - `install.sh` accepts `--preset FILE` anywhere on the command line, and preset
      values now actually drive the option checklist; they were loaded and then
      ignored. `Y`/`N` and `ON`/`OFF` are both accepted
    - `install.sh` refuses to run on releases older than Ubuntu 26.04, and the
      banner/titles no longer claim Ubuntu 25.10+ or a fixed Hyprland 0.52.2
    - Choosing SDDM while another login manager is active now skips SDDM and keeps
      going; it previously re-executed the whole installer from the start
    - `update-deps.sh` exits non-zero when any step failed (it always exited 0)
    - A missing `TERM` no longer aborts the install scripts: colours are skipped
      instead of letting `tput` fail under `set -e`
    - Install scripts share `init_script` for the repo-root/log-path preamble,
      replacing the copy-pasted block and the ad-hoc log-name counter in `zsh.sh`
    - `uninstall.sh` restores the backups the installer leaves behind
      (`~/.zshrc-backup`, `~/.zprofile-backup`, `/etc/sddm.conf.bak`) instead of
      leaving the pre-install config stranded next to the new one
    - `uninstall.sh` also offers to restore `~/.config` backups left by the
      dotfiles installer (`.bak`, `.bak.<tag>`, `.old`, `-backup`, `_backup`),
      keeping the current entry as `<name>.replaced-<timestamp>`
    - `uninstall.sh` can run unattended: `--yes`, `--all`, `--packages LIST`,
      `--dirs LIST` and `--dry-run` skip every whiptail prompt (unknown names are
      rejected). With `--yes` all detected backups are restored
    - `uninstall.sh` uses the same terminal-safe colours as the install scripts and
      only clears a real terminal, so its output survives being piped
    - `README.md` documents the uninstall options (`--yes`, `--all`, `--packages`,
      `--dirs`, `--dry-run`) and which backups the uninstall restores
    - Quickshell is required on Ubuntu 26.04+ (the dotfiles now ship several
      Quickshell apps); `install.sh` aborts when it fails instead of warning and
      continuing. AGS remains available as an alternative overview.
    - `quickshell.sh` skips the source build when an install at `0.3.0` or newer is
      already present, and rebuilds when it is older or unrunnable
    - `update-deps.sh` installs or rebuilds Quickshell when it is missing or below
      `0.3.0`
    - `waybar.sh` skips the build only when the installed build is at or above
      `WAYBAR_MIN_VERSION`; an existing but outdated build is rebuilt instead of
      being treated as done. `03-Final-Check.sh` and `update-deps.sh` enforce the
      same minimum
    - `hyprlock.sh` and `hypridle.sh` skip the source build when a packaged build
      at or above the pinned tag is installed (the PPA ships newer binaries, and a
      source build would shadow them in `/usr/local/bin`)
    - `install.sh --dry-run` prints the same PPA-vs-Ubuntu verdict as the final
      check, so it shows whether the PPA actually carries this release
    - `install.sh` clears the Hyprland source record at the start of a run, so the
      final check never reports how a previous attempt installed it
    - `hyprland-ppa.sh` checks the series the PPA is enabled for against the
      running codename before `apt update`, stops with a clear message when
      `apt update` fails, and logs why individual packages were skipped
    - `update-deps.sh` sources the shared helpers and reports the release and PPA
      state in its summary; status lines from the final check are no longer
      counted as missing packages
    - `update-deps.sh --dry-run` prints the same Hyprland source and PPA state as
      its summary
    - `install.sh` no longer aborts when an optional component fails: the failing
      script is named, the install continues, and everything that failed is
      listed once at the end. Required steps (dependencies, packages, Hyprland,
      Waybar, Quickshell) still stop the run
    - `install.sh` rejects an unknown install mode right after argument parsing,
      instead of after the whole Hyprland stage
    - `install.sh` pauses once after the Hyprland and dotfiles stages when
      something failed, before the screen is cleared: it prints one summary and
      offers to retry the failed optional components, continue anyway, or abort
      (a non-interactive run prints the summary and continues)
    - `dotfiles-branch.sh` now fails when `copy.sh` fails or does not create
      `~/.config/hypr`. It always exited 0, so a broken copy was reported as an
      installed dots setup and the final check had nothing to report
    - `03-Final-Check.sh` prints the optional components that did not install
      (recorded in `Install-Logs/optional-failures.txt`) after the Hyprland
      source line; printed only, never appended to its package log
    - `install.sh` falls back to the Ubuntu repositories when the PPA path fails,
      and the recorded reason is reported by the final check instead of the
      install simply aborting
    - Every shell script is shellcheck-clean, and `tests/run-all.sh` now fails on
      any shellcheck finding so the baseline cannot drift
- Fixed:
    - `ags.sh` stopped failing during install: `libaudit-dev` is installed because
      pam's `pkg-config` entry pulls in `audit.pc`, the `apt build-dep pam` call
      (which needs `deb-src` sources most systems lack) is gone, and the global
      TypeScript is pinned to `5` because ags v1.9.0's tsconfig no longer
      compiles under 6/7. Failed `npm install` / `meson setup` / `meson install`
      steps now name the log and exit non-zero instead of dying silently or
      reporting success, and the compile uses the `tsc` pinned in
      `package.json`
    - `ags.sh`, `hyprland-ubuntu.sh`, `hyprlock.sh`, `rofi-wayland.sh`,
      `sddm.sh`, `sddm_theme.sh` and `yazi.sh` set `pipefail`, so a failed
      `cmd | tee` is reported instead of tee's success status
    - `build_dep` reports a failed `apt build-dep` and returns success, since the
      `-dev` packages each caller needs are already in its own list; the failure
      used to be counted as a successful step
    - `hyprlock.sh`, `hypridle.sh` and `rog.sh` fail the step when the source
      install or the clone fails. They printed the error and then ended 0, so
      `install.sh` listed them as installed; they now show up in the optional
      component summary instead
    - `tests/source-install-failure-test.sh` pins the exit status of `ags.sh`
      (clone, `npm install`, `meson setup`, `meson install` and a successful
      build), `hyprlock.sh` (clone, `cmake --install`), `hypridle.sh`
      (`cmake --install`) and `rog.sh` (one project failing while the other
      still installs) by running them in a throwaway copy of the repo with
      git/npm/meson/cmake/make/curl/pkg-config/dpkg-query/sudo stubbed, so no
      build or sudo is needed
    - `hyprlock.sh` no longer runs `apt build-dep pam`: that needs `deb-src`
      sources most systems lack, and it installs pam's own build dependencies
      rather than the pam headers hyprlock links against, which
      `libpam0g-dev` in the package list already provides
    - `00-dependencies.sh` no longer runs `apt build-dep wlroots`: nothing in
      the repo builds wlroots from source (Hyprland arrives from the PPA or the
      Ubuntu repositories, wlroots with it) and that script never enables
      `deb-src`, so the call could only fail and be reported as a warning.
      `waybar.sh` keeps its call, the one place where a package really is built
      from source and `deb-src` is enabled for it
    - `packages.sh` listed `hyprland-guiutils`, which Ubuntu 26.04 (resolute)
      does not package, so `01-hypr-pkgs.sh` aborted every clean install with
      "Unable to locate package hyprland-guiutils". It now uses
      `hyprland-qtutils`, which ships `hyprland-dialog` on 26.04 and is the
      transitional dummy for `hyprland-guiutils` on 26.10+
    - `03-Final-Check.sh` exits non-zero when something is missing, so
      `update-deps.sh` and CI can gate on it (`install.sh` still ignores the
      status and shows the summary)
    - `sddm_theme.sh` copied the JetBrains Mono font into a nested
      `JetBrainsMonoNerd/JetBrainsMonoNerd` directory, and now skips the copy
      cleanly when `fonts.sh` did not run
    - `uninstall.sh` wrote its selections to fixed `/tmp` paths that were never
      removed; they now live in a private `mktemp -d` cleaned up on exit
    - `hyprland-ubuntu.sh` installed `waybar` from APT, which `waybar.sh` then
      purged before building from source
    - `install_package` / `re_install_package` now return non-zero and record the
      package in `Install-Logs/failed-packages.txt`; the previous always-success
      return made every `execute_script … || exit 1` guard in `install.sh`
      unreachable. Failed dependency/package installs now stop the installer
      instead of being only reported by the final check
    - `install.sh` ran the dependency step through `| tee`, so its failure guard
      tested tee's status and could never fire
    - `fonts.sh` retried the JetBrains Mono download on a condition that tested
      `tee`, so the retry loop always stopped after the first attempt; extraction
      is now guarded and the previous font copy is only replaced on a successful
      download
    - `nvidia.sh` appended its modprobe/initramfs lines on every run (a multi-line
      `grep` test can never match); each line is now added once
    - `hypridle.sh` used `getconf NPROCESSORS_CONF` (missing underscore) as the
      `-j` fallback, and checked the exit status of `tee` instead of the package
      install
    - `waybar.sh` configures Waybar with `-Dtests=disabled`, so a broken or
      missing Catch2 install can no longer fail the build
    - `hyprlock`/`hypridle` source builds no longer fail with missing `hyprlang`
      and `hyprutils` pkg-config modules: those headers are only installed for the
      fallback source build (`00-dependencies.sh` purges them on purpose)
    - `02-pre-cleanup.sh` no longer deletes `/usr/local/bin/waybar`, which forced
      a full Waybar source build on every install run and defeated the
      `WAYBAR_MIN_VERSION` skip check
    - `uninstall_package` redirected `apt autoremove` output before its `grep`
      filter, so the filter never saw the output; the filtered text now goes to
      the log
    - `has_apt_candidate` read `apt-cache policy` in the user's locale, so on
      non-English systems the translated `Candidate:` label made every package
      look unavailable and `hyprland-ppa.sh` claimed the release was unsupported.
      The lookup now runs under `LC_ALL=C`, scoped with `local` so the rest of the
      script keeps the user's locale
- Removed:
    - `install-scripts/force-hl-update.sh` (unreferenced; it installed every .deb
      in `/var/cache/apt/archives` with `--force-overwrite`)
- Docs:
    - `building-quickshell.md` no longer describes Quickshell as an optional menu
      item
    - `README.md` documents the automatic PPA-to-Ubuntu fallback and the test
      scripts that cover it

## Oct 2026

- Added:
    - `lua5.4` (provides `luac`) to default package dependencies
    - `lua5.4` and `hyprland-guiutils` package checks, and `luac` / `hyprland-dialog` binary checks to `03-Final-Check.sh`

## Sep 2026

- Removed:
    - quickshell from menu
        - Installed by default
- Added:
    - Dep check for `util-linux`
- Fixed:
    - `update-deps.sh` now builds `waybar` from source (was missing the `waybar.sh`
      step, so the APT package was left in place and hyprland LUA workflows broke)
    - `update-deps.sh` summary now reports multi-word missing entries such as
      `waybar (source build)` instead of dropping them

## Aug 2026

- Added:
    - `install-scripts/waybar.sh` to build waybar from source (matches Debian)
    - `install-scripts/nwg-dock-hyprland.sh` Builds from source
- Changed:
    - `waybar` removed from APT package list (`01-hypr-pkgs.sh`); now purges any APT
      package and builds from source only — prevents apt upgrades from silently
      overriding the source-built binaryZ
- Fixed:
    - Installer was installing ubuntu repo not PPA by default
    - Fixed final check for `swww` to `awww`
    - `sddm_theme.sh` overwritting background image
    - Yazi installed from GH repository
    - waybar build error missing dependencies

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
