#!/usr/bin/env bash
# shellcheck disable=SC2034  # colours and helpers are used by the scripts that source this file
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Global Functions for Scripts #

# Keep the install scripts strict by default. Scripts that manage their own
# error handling (update-deps.sh) or only need the helpers (install.sh
# --dry-run) opt out with GF_STRICT=0.
if [ "${GF_STRICT:-1}" = "1" ]; then
  set -e
fi

# Set some colors for output messages. When there is no terminal (or TERM is
# unset, as in cron/CI/plain `sh -c`), leave them empty instead of letting tput
# fail - this file runs under `set -e`, so a failing tput would abort the caller.
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

# Resolve repo root and build directories based on this file location
GF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(readlink -f "$GF_DIR/..")"
export REPO_ROOT

# Build directories (override with env to customize)
BUILD_ROOT="${BUILD_ROOT:-$REPO_ROOT/build}"
BUILD_SRC="${BUILD_SRC:-$BUILD_ROOT/src}"
BUILD_BIN="${BUILD_BIN:-$BUILD_ROOT/bin}"
export BUILD_ROOT BUILD_SRC BUILD_BIN

# Ensure standard directories exist. GF_SKIP_SETUP=1 keeps that out of paths
# that only need the helper functions (e.g. `install.sh --dry-run`).
if [ "${GF_SKIP_SETUP:-0}" != "1" ]; then
  mkdir -p "$REPO_ROOT/Install-Logs" "$BUILD_SRC" "$BUILD_BIN"
fi

# ─── Script bootstrap ───────────────────────────────────────────────────────
# Standardises the boilerplate install scripts need: run from the repo root and
# log to an absolute, collision-free path. Call as: init_script <log-suffix>
init_script() {
  local suffix="${1:-install}"
  local base path n
  cd "$REPO_ROOT" || { echo "${ERROR} Failed to change directory to $REPO_ROOT"; exit 1; }
  base="$REPO_ROOT/Install-Logs/install-$(date +%d-%H%M%S)_${suffix}.log"
  path="$base"
  n=1
  # Claim the path atomically, so two scripts starting within the same second
  # cannot end up appending to one log file.
  while ! ( set -o noclobber; : > "$path" ) 2>/dev/null; do
    path="${base%.log}_${n}.log"
    n=$((n + 1))
  done
  LOG="$path"
}

# Show progress function
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○" \
                      "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●") 
    local i=0

    [ -n "${TERM:-}" ] && tput civis 2>/dev/null || true
    printf "\r${INFO} Installing ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p $pid &> /dev/null; do
        printf "\r${INFO} Installing ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))  
        sleep 0.3  
    done

    printf "\r${INFO} Installing ${YELLOW}%s${RESET} ... Done!%-20s \n\n" "$package_name" ""
    [ -n "${TERM:-}" ] && tput cnorm 2>/dev/null || true
}


# ─── Install failure reporting ───────────────────────────────────────────────
# Failed installs are recorded here so that 00-dependencies.sh, 01-hypr-pkgs.sh
# and update-deps.sh can report a non-zero result instead of continuing silently.
install_failure_count=0

record_install_failure() {
    local name="$1"
    local file="$REPO_ROOT/Install-Logs/failed-packages.txt"
    install_failure_count=$((install_failure_count + 1))
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$name" >> "$file"
}

# Prints the install outcome; returns non-zero when any package failed.
report_install_failures() {
    if [ "${install_failure_count:-0}" -eq 0 ]; then
        echo -e "${OK} All requested packages are installed."
        return 0
    fi
    echo -e "${ERROR} ${install_failure_count} package(s) failed to install. See ${YELLOW}$REPO_ROOT/Install-Logs/failed-packages.txt${RESET} and the install log."
    return 1
}

# Function for installing packages with a progress bar
install_package() { 
  if dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ; then
    echo -e "${INFO} ${MAGENTA}$1${RESET} is already installed. Skipping..."
  else 
    (
      stdbuf -oL sudo apt install -y "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1" 
    
    # Double check if the package successfully installed
    if dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"; then
        echo -e "\e[1A\e[K${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
    else
        echo -e "\e[1A\e[K${ERROR} ${YELLOW}$1${RESET} failed to install. Please check the install.log. You may need to install it manually. Sorry, I have tried :("
        record_install_failure "$1"
        return 1
    fi
  fi
}

# Function for build depencies with a progress bar
build_dep() { 
  echo -e "${INFO} building dependencies for ${MAGENTA}$1${RESET} "
    (
      stdbuf -oL sudo apt build-dep -y "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1" 
}

# Function for cargo install with a progress bar
cargo_install() { 
  echo -e "${INFO} installing ${MAGENTA}$1${RESET} using cargo..."
    (
      stdbuf -oL cargo install "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1" 
}

# Function for re-installing packages with a progress bar
re_install_package() {
    (
        stdbuf -oL sudo apt install --reinstall -y "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    
    PID=$!
    show_progress $PID "$1" 
    
    if dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"; then
        echo -e "\e[1A\e[K${OK} Package ${YELLOW}$1${RESET} has been successfully re-installed!"
    else
        # Package not found, reinstallation failed
        echo -e "${ERROR} ${YELLOW}$1${RESET} failed to re-install. Please check the install.log. You may need to install it manually. Sorry, I have tried :("
        record_install_failure "$1"
        return 1
    fi
}

# Function to check if a package has an available candidate in APT
has_apt_candidate() {
  # apt-cache translates its field labels under non-English locales (e.g.
  # "Candidate:" -> "Installationskandidat:"), which makes the awk match below fail
  # and report every package as unavailable. Force the C locale, scoped locally
  # so LC_ALL from the caller is overridden without leaking into the rest of
  # the script.
  local cand LC_ALL=C LANG=C
  cand="$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')"
  [ -n "$cand" ] && [ "$cand" != "(none)" ]
}

# Explains a failed has_apt_candidate check: prints the raw `apt-cache policy`
# output (forced to the C locale) so it is clear whether APT does not know the
# package at all or knows it but has nothing installable on this release.
apt_candidate_report() {
  local pkg="$1" raw cand
  raw="$(LC_ALL=C LANG=C apt-cache policy "$pkg" 2>&1)"
  if [ -z "$raw" ]; then
    printf "  apt-cache has no entry for '%s': no configured repository offers it.\n" "$pkg"
    return 0
  fi
  cand="$(printf '%s\n' "$raw" | awk -F': ' '/^[[:space:]]*Candidate:/ {print $2; exit}')"
  case "$cand" in
    ''|'(none)')
      printf "  '%s' is in the package lists but has no installable version on this Ubuntu release.\n" "$pkg"
      ;;
    *)
      printf "  apt-cache reports candidate %s for '%s'.\n" "$cand" "$pkg"
      ;;
  esac
  printf '%s\n' "$raw" | sed 's/^/    /'
}

# Directory holding APT source definitions; overridable so the PPA series check
# can be exercised against fixtures instead of the live system.
APT_SOURCES_DIR="${APT_SOURCES_DIR:-/etc/apt/sources.list.d}"

# Series the Hyprland PPA is enabled for, one per line. Covers both the
# one-line (.list) and the deb822 (.sources) form add-apt-repository writes.
ppa_suites() {
  local f
  for f in "$APT_SOURCES_DIR"/*cppiber*hyprland*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.sources)
        awk -F': *' '/^Suites:/ { print $2 }' "$f"
        ;;
      *)
        awk '
          /^[[:space:]]*deb(-src)?[[:space:]]/ {
            sub(/^[[:space:]]*deb(-src)?[[:space:]]+/, "")
            if ($0 ~ /^\[/) { sub(/^\[[^]]*\][[:space:]]*/, "") }
            print $2
          }
        ' "$f"
        ;;
    esac
  done | tr ' ' '\n' | sed '/^$/d' | sort -u
}

# Exit 0 when the PPA covers this release: the series it is enabled for
# includes the running codename. An unknown codename or no PPA source files
# means "cannot tell", which must never block the install. The codename can be
# passed in by the tests.
ppa_series_ok() {
  # ${1-...}, not ${1:-...}: an explicitly passed empty codename means
  # "cannot tell", while no argument means detect it.
  local codename="${1-$(ubuntu_codename)}" series
  [ -n "$codename" ] || return 0
  series="$(ppa_suites)"
  [ -n "$series" ] || return 0
  printf '%s\n' "$series" | grep -qx "$codename"
}

# Codename of the running Ubuntu release (e.g. "noble"); empty when unknown.
ubuntu_codename() {
  local cn=""
  if [ -r /etc/os-release ]; then
    cn="$( . /etc/os-release 2>/dev/null && printf '%s' "${VERSION_CODENAME:-}" )"
  fi
  if [ -z "$cn" ] && command -v lsb_release >/dev/null 2>&1; then
    cn="$(lsb_release -sc 2>/dev/null || true)"
  fi
  printf '%s' "$cn"
}

# Where hyprland-ppa.sh / hyprland-ubuntu.sh record how Hyprland was provided,
# for 03-Final-Check.sh to print. Overridable so tests can use a scratch file.
hyprland_source_file() {
  printf '%s' "${HYPRLAND_SOURCE_FILE:-${REPO_ROOT:-$PWD}/Install-Logs/hyprland-source.txt}"
}

# Records how Hyprland was provided: one line, two tab-separated fields, the
# outcome (ppa, ppa-failed or ubuntu) and an optional reason. Deliberately not
# written to the install log, which update-deps.sh reads as a package list.
record_hyprland_source() { # record_hyprland_source <outcome> [reason]
  local file
  file="$(hyprland_source_file)"
  mkdir -p "$(dirname "$file")"
  printf '%s\t%s\n' "$1" "${2:-}" >"$file"
}

# Prints one field of the recorded line: 1 for the outcome, 2 for the reason.
hyprland_source_field() { # hyprland_source_field <1|2>
  local file
  file="$(hyprland_source_file)"
  [ -r "$file" ] || return 0
  cut -f"$1" "$file"
}

# Function for removing packages
uninstall_package() {
  local pkg="$1"

  # Checking if package is installed
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" ; then
    echo -e "${NOTE} removing $pkg ..."
    sudo apt autoremove -y "$1" 2>&1 | grep -v "error: target not found" >> "$LOG" || true
    
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" ; then
      echo -e "\e[1A\e[K${OK} ${MAGENTA}$1${RESET} removed."
    else
      echo -e "\e[1A\e[K${ERROR} $pkg Removal failed. No actions required."
      return 1
    fi
  else
    echo -e "${INFO} Package $pkg not installed, skipping."
  fi
  return 0
}
