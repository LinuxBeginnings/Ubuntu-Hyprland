#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Exit-status test for the scripts that build a package from source.
#
# Each case runs the real script in a throwaway copy of the repo, with PATH
# holding only stub tools, so nothing is cloned, compiled, downloaded or
# installed with sudo. A stub exits with the status named in its status file,
# which is how a failing step is simulated without a broken toolchain.
#
# The scripts must fail the step when the clone or the build fails: install.sh
# treats the exit status as the verdict, so ending 0 after an error listed a
# broken build as installed.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BIN="$WORK/bin"
mkdir -p "$BIN"

checks=0
failures=0

pass() { checks=$((checks + 1)); printf '  ok   %s\n' "$1"; }
fail() { checks=$((checks + 1)); failures=$((failures + 1)); printf '  FAIL %s\n' "$1"; }

same() { # same <description> <want> <got>
    if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (want '$2', got '$3')"; fi
}

has() { # has <description> <literal text>
    if grep -qF -- "$2" "$RUN_OUT"; then pass "$1"; else fail "$1 (output has no '$2')"; fi
}

hasnt() {
    if grep -qF -- "$2" "$RUN_OUT"; then fail "$1 (output has '$2')"; else pass "$1"; fi
}

# ─── stub PATH ───────────────────────────────────────────────────────────────
# Link the host tools the scripts need. hyprlock/hypridle/ags are deliberately
# left out: their absence is what makes the scripts take the build path.
for tool in bash sh env mktemp cat date tee grep sed awk cut tr head tail sort \
            uniq cp mv rm mkdir rmdir chmod readlink dirname basename nproc \
            getconf ps sleep tput stdbuf ln touch; do
    src="$(command -v "$tool" 2>/dev/null || true)"
    if [ -n "$src" ] && [ -x "$src" ]; then ln -sf "$src" "$BIN/$tool"; fi
done

# Exits with the status recorded for <prog> <arg> <dir>, or 0 when none is.
cat > "$BIN/stub-status" <<'STUB'
#!/usr/bin/env bash
prog="$1"
arg="${2:-}"
dir="${3:-}"
while [ "${arg#-}" != "$arg" ]; do arg="${arg#-}"; done
for f in "$STUB_STATUS/$prog-$arg-$dir" "$STUB_STATUS/$prog-$arg" \
         "$STUB_STATUS/$prog-$dir" "$STUB_STATUS/$prog"; do
    if [ -f "$f" ]; then exit "$(cat "$f")"; fi
done
exit 0
STUB

# git clone creates the destination, then reports the recorded status.
cat > "$BIN/git" <<'STUB'
#!/usr/bin/env bash
here="$(dirname "$0")"
"$here/stub-status" git "${1:-}" "$(basename "$PWD")" || exit "$?"
# Skip "clone", every option and the value of the options that take one, so
# "-b v0.3.0" cannot be mistaken for the URL.
url=""
dest=""
shift || exit 0
while [ "$#" -gt 0 ]; do
    case "$1" in
        -b|--branch|-o|--origin|--depth) shift 2; continue ;;
        -*) shift; continue ;;
    esac
    if [ -z "$url" ]; then url="$1"; else dest="$1"; fi
    shift
done
if [ -z "$dest" ]; then
    dest="${url##*/}"
    dest="${dest%.git}"
fi
if [ -n "$dest" ]; then mkdir -p "$dest"; fi
exit 0
STUB

for tool in npm meson cmake make curl pkg-config; do
    cat > "$BIN/$tool" <<'STUB'
#!/usr/bin/env bash
exec "$(dirname "$0")/stub-status" "$(basename "$0")" "${1:-}" "$(basename "$PWD")"
STUB
done

# Runs the build tools so their status is seen; everything else (apt, tee, sed,
# systemctl, chmod, ...) is pretended to succeed, so nothing outside the sandbox
# is touched.
cat > "$BIN/sudo" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
    meson|cmake|make|npm|ninja) exec "$@" ;;
    *) exit 0 ;;
esac
STUB

# The scripts skip their work when the package looks installed; hyprlock and
# hypridle must look absent so the clone/build path runs.
cat > "$BIN/dpkg-query" <<'STUB'
#!/usr/bin/env bash
pkg="${*: -1}"
case "$pkg" in
    hyprlock|hypridle|hyprland|hyprcursor|hyprlang) printf 'Status: not-installed\n' ;;
    *) printf 'Status: install ok installed\n' ;;
esac
STUB

find "$BIN" -type f -exec chmod +x {} +

# ─── harness ─────────────────────────────────────────────────────────────────
RUN_OUT=""
RUN_STATUS=0

run_script() { # run_script <case> <script> [<status-file>=<status> ...]
    local name="$1" script="$2" dir kv
    shift 2
    dir="$WORK/case-$name"
    mkdir -p "$dir/install-scripts" "$dir/status" "$dir/home/.cargo"
    : > "$dir/home/.cargo/env"
    cp "$REPO_ROOT"/install-scripts/*.sh "$dir/install-scripts/"
    for kv in "$@"; do
        printf '%s\n' "${kv#*=}" > "$dir/status/${kv%%=*}"
    done
    RUN_OUT="$dir/out"
    ( cd "$dir" &&
      HOME="$dir/home" TERM=xterm-256color PATH="$BIN" STUB_STATUS="$dir/status" \
      bash "$dir/install-scripts/$script" ) >"$RUN_OUT" 2>&1
    RUN_STATUS=$?
}

# ─── ags.sh ──────────────────────────────────────────────────────────────────
printf '\n%s\n' "ags: git clone fails"
run_script ags-clone ags.sh git-clone=1
same "exits 1" 1 "$RUN_STATUS"
has "reports the download failure" "Failed to download"

printf '\n%s\n' "ags: npm install fails"
run_script ags-npm ags.sh npm-install-ags_v1.9.0=1
same "exits 1" 1 "$RUN_STATUS"
has "names the npm step" "npm install failed"
hasnt "does not claim a successful install" "installed successfully"

printf '\n%s\n' "ags: meson setup fails"
run_script ags-setup ags.sh meson-setup-ags_v1.9.0=1
same "exits 1" 1 "$RUN_STATUS"
has "names the configure step" "configure (meson setup) failed"

printf '\n%s\n' "ags: meson install fails"
run_script ags-install ags.sh meson-install-ags_v1.9.0=1
same "exits 1" 1 "$RUN_STATUS"
has "reports the installation failure" "Installation failed"
has "points at the log" "_ags2.log"
hasnt "does not claim a successful install" "installed successfully"

printf '\n%s\n' "ags: everything succeeds"
run_script ags-success ags.sh
same "exits 0" 0 "$RUN_STATUS"
has "reports success" "installed successfully"

# ─── hyprlock.sh ─────────────────────────────────────────────────────────────
printf '\n%s\n' "hyprlock: git clone fails"
run_script hyprlock-clone hyprlock.sh git-clone=1
same "exits 1" 1 "$RUN_STATUS"
has "reports the download failure" "Download failed"

printf '\n%s\n' "hyprlock: cmake --install fails"
run_script hyprlock-install hyprlock.sh cmake-install-hyprlock=1
same "exits 1" 1 "$RUN_STATUS"
has "reports the installation failure" "Installation failed"
has "points at the log" "_hyprlock2.log"
hasnt "does not claim a successful install" "has been successfully installed"

# ─── hypridle.sh ─────────────────────────────────────────────────────────────
printf '\n%s\n' "hypridle: cmake --install fails"
run_script hypridle-install hypridle.sh cmake-install-hypridle=1
same "exits 1" 1 "$RUN_STATUS"
has "reports the installation failure" "Installation failed"
has "points at the log" "_hypridle2.log"
hasnt "does not claim a successful install" "installed successfully"

# ─── rog.sh ──────────────────────────────────────────────────────────────────
printf '\n%s\n' "rog: the first project fails to install"
run_script rog rog.sh make-install-asusctl=1
same "exits 1" 1 "$RUN_STATUS"
has "reports the asusctl failure" "Installation failed for asusctl"
hasnt "does not claim asusctl installed" "asusctl installed successfully"
has "still installs the second project" "supergfxctl installed successfully"

# ─── sandbox ─────────────────────────────────────────────────────────────────
printf '\n%s\n' "nothing was written outside the sandbox"
leaked=0
for d in ags_v1.9.0 hyprlock hypridle asusctl supergfxctl; do
    if [ -e "$REPO_ROOT/$d" ]; then leaked=1; fi
done
same "no clone landed in the repo" 0 "$leaked"
inside=0
for d in "$WORK/case-ags-success/ags_v1.9.0" "$WORK/case-hyprlock-install/hyprlock" \
         "$WORK/case-hypridle-install/hypridle" "$WORK/case-rog/asusctl"; do
    if [ -d "$d" ]; then inside=$((inside + 1)); fi
done
same "every clone stayed in the sandbox" 4 "$inside"

printf '\n'
if [ "$failures" -eq 0 ]; then
    printf '%d checks passed\n' "$checks"
    exit 0
fi
printf '%d of %d checks failed\n' "$failures" "$checks"
exit 1
