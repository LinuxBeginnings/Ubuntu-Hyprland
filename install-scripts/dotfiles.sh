#!/usr/bin/env bash
# 💫 https://github.com/JaKooLit 💫 #
# Ensure Hyprland-Dots is synced to the latest from the main branch

set -euo pipefail

# specific branch or release (default: main)
dots_tag="main"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."

# Move to repo root so logs land in Install-Logs under the project
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

# Source shared functions (colors, LOG setup)
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"; exit 1
fi

REPO_URL="https://github.com/JaKooLit/Hyprland-Dots.git"
BRANCH="$dots_tag"
TARGET_DIR="Hyprland-Dots-Ubuntu"

printf "${NOTE} Syncing KooL's Hyprland Dots (${YELLOW}%s${RESET}) from ${YELLOW}%s${RESET}...\n" "$BRANCH" "$REPO_URL"

if [ -d "$TARGET_DIR/.git" ]; then
    cd "$TARGET_DIR"
    # Ensure remote points to the canonical repo
    git remote set-url origin "$REPO_URL" || true
    # Fetch just the target branch and reset to it
    git fetch --depth=1 origin "$BRANCH"
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git checkout "$BRANCH"
    else
        git checkout -b "$BRANCH" "origin/$BRANCH"
    fi
    git reset --hard "origin/$BRANCH"
    git clean -fdx
else
    # If a non-git directory exists, remove it to ensure a clean clone
    if [ -d "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR/.git" ]; then
        echo "${WARN} Existing non-git directory $TARGET_DIR detected. Removing it to re-clone..."
        rm -rf "$TARGET_DIR"
    fi
    if git clone --branch "$BRANCH" --depth=1 "$REPO_URL" "$TARGET_DIR"; then
        cd "$TARGET_DIR"
    else
        echo -e "${ERROR} Can't clone ${YELLOW}$REPO_URL${RESET} (branch ${YELLOW}$BRANCH${RESET}) into ${YELLOW}$TARGET_DIR${RESET}"
        exit 1
    fi
fi

# Run copy.sh from the dotfiles repo
chmod +x copy.sh
./copy.sh

printf "\n%.0s" {1..2}
