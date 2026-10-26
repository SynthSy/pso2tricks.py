#!/usr/bin/env bash
#
# Auto installer for the lazy
# Setup the required user dependencies to
# execute pso2tricks.py
#
# Downloads the following:
# - Installs uv (https://astral.sh/uv) into the pso2_files folder.
#   uv downloads its own Python and the "requests" library on first run.
# - Downloads pso2tricks and points its shebang at that uv binary,
#   so it can be run directly as ./pso2tricks from any directory.
#
# Install folder: ~/pso2_files (override with PSO2_FILES_LOCATION=/some/path)
#
# If you have suggestions, feel free to let us know.
#
# pso2tricks.py is licensed under the WTFPL.

set -euo pipefail

clear 2>/dev/null || true
echo -e "\e[0m\c"

# shellcheck disable=SC2016
echo '
 █████╗ ██████╗ ██╗  ██╗███████╗      ██╗      █████╗ ██╗   ██╗███████╗██████╗
██╔══██╗██╔══██╗██║ ██╔╝██╔════╝      ██║     ██╔══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
███████║██████╔╝█████╔╝ ███████╗█████╗██║     ███████║ ╚████╔╝ █████╗  ██████╔╝
██╔══██║██╔══██╗██╔═██╗ ╚════██║╚════╝██║     ██╔══██║  ╚██╔╝  ██╔══╝  ██╔══██╗
██║  ██║██║  ██║██║  ██╗███████║      ███████╗██║  ██║   ██║   ███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝      ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
                    --- pso2tricks pre-check setup ---
'

###############################################################################
# Globals                                                                     #
###############################################################################

# SYSTEM REQUIREMENTS
readonly PSO2TRICKS_DEPENDS=(curl uname mktemp)

UNAME_M="$(uname -m)"
readonly UNAME_M

UNAME_U="$(uname -s)"
readonly UNAME_U

readonly UV_INSTALLER="https://astral.sh/uv/install.sh"
readonly PSO2TRICKS_URL="https://raw.githubusercontent.com/SynthSy/pso2tricks.py/refs/heads/main/pso2tricks.py"

PSO2_FILES="${PSO2_FILES_LOCATION:-$HOME/pso2_files}"
PSO2_FILES="${PSO2_FILES%/}"
readonly PSO2_FILES
readonly UV_BIN="$PSO2_FILES/uv"

# COLORS
readonly COLOUR_RESET='\e[0m'
readonly aCOLOUR=(
    '\e[38;5;154m' # green  	| Lines, bullets and separators
    '\e[1m'        # Bold white	| Main descriptions
    '\e[90m'       # Grey		| Credits
    '\e[91m'       # Red		| Update notifications Alert
    '\e[33m'       # Yellow		| Emphasis
)

readonly GREEN_LINE=" ${aCOLOUR[0]}─────────────────────────────────────────────────────$COLOUR_RESET"
# shellcheck disable=SC2034 # kept for future use
readonly GREEN_BULLET=" ${aCOLOUR[0]}-$COLOUR_RESET"
# shellcheck disable=SC2034
readonly GREEN_SEPARATOR="${aCOLOUR[0]}:$COLOUR_RESET"

###############################################################################
# Helpers                                                                     #
###############################################################################

#######################################
# Custom printing function
# Arguments:
#   $1 0:OK   1:FAILED (exits)  2:INFO  3:NOTICE
#   $2 message
#######################################

Show() {
    case "$1" in
    # OK
    0) echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]}  OK  $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2" ;;
    # FAILED
    1)
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[3]}FAILED$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2" >&2
        exit 1
        ;;
    # INFO
    2) echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]} INFO $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2" ;;
    # NOTICE
    3) echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[4]}NOTICE$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2" ;;
    esac
}

# Any unexpected error (set -e) ends up here instead of exiting silently.
trap 'Show 1 "Something went wrong on line $LINENO. Nothing outside $PSO2_FILES was changed."' ERR

# shellcheck disable=SC2329 # unused helpers, kept on purpose
Warn() {
    echo -e "${aCOLOUR[3]}$1$COLOUR_RESET"
}

# shellcheck disable=SC2329
GreyStart() {
    echo -e "${aCOLOUR[2]}\c"
}

# shellcheck disable=SC2329
ColorReset() {
    echo -e "$COLOUR_RESET\c"
}

# Clear Terminal
# shellcheck disable=SC2329
Clear_Term() {

    # Without an input terminal, there is no point in doing this.
    [[ -t 0 ]] || return 0

    # Printing terminal height - 1 newlines seems to be the fastest method that is compatible with all terminal types.
    local lines i newlines=''
    lines=$(tput lines 2>/dev/null || echo 24)

    for ((i = 1; i < lines; i++)); do newlines+='\n'; done
    echo -ne "\e[0m$newlines\e[H"

}

# Check file exists (returns 0 = exists, 1 = missing, so it works with "if exist_file x")
# shellcheck disable=SC2329
exist_file() {
    [[ -e "$1" ]]
}

Check_OS() {
    if [[ $UNAME_U == *Linux* ]]; then
        Show 0 "Your System is : $UNAME_U ($UNAME_M)"
    else
        Show 1 "This script is only for Linux."
    fi
}

Check_Depends() {
    local dep
    for dep in "${PSO2TRICKS_DEPENDS[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || Show 1 "'$dep' is required but was not found."
    done
    Show 0 "Required tools found."
}

Write_Check() {
    if [[ ! -d $PSO2_FILES ]]; then
        Show 3 "Could not find $PSO2_FILES, making one now..."
        mkdir -p "$PSO2_FILES" || Show 1 "Could not create $PSO2_FILES."
    fi
    if [[ -w $PSO2_FILES ]]; then
        Show 0 "Write permissions are granted for $PSO2_FILES."
    else
        Show 1 "No write permissions in $PSO2_FILES. Exiting."
    fi
}

Download_uv() {
    Show 2 "Installing uv into $PSO2_FILES..."
    # UV_UNMANAGED_INSTALL: put the binaries straight into this folder and
    # never touch the user's shell profile / PATH.
    curl -LsSf "$UV_INSTALLER" | env UV_UNMANAGED_INSTALL="$PSO2_FILES" sh
    [[ -x $UV_BIN ]] || Show 1 "uv was not installed to $UV_BIN."
    Show 0 "uv $("$UV_BIN" --version | awk '{print $2}') installed."
}

Download_pso2tricks() {
    local tmp
    tmp="$(mktemp "$PSO2_FILES/.pso2tricks.XXXXXX")"
    curl -fsSL -o "$tmp" "$PSO2TRICKS_URL" || { rm -f "$tmp"; Show 1 "Could not download pso2tricks."; }

    # Replace (or add) the shebang so it uses OUR uv by absolute path.
    # A relative "./uv" only works when you happen to be inside pso2_files.
    {
        printf '#!/usr/bin/env -S "%s" run --script\n' "$UV_BIN"
        if head -n 1 "$tmp" | grep -q '^#!'; then tail -n +2 "$tmp"; else cat "$tmp"; fi
    } >"$PSO2_FILES/pso2tricks"
    rm -f "$tmp"
    chmod +x "$PSO2_FILES/pso2tricks"
    Show 0 "pso2tricks downloaded to $PSO2_FILES/pso2tricks"
}

Warm_Cache() {
    # First run makes uv fetch python + requests; do it now so the user
    # sees any network problem here instead of in the middle of a download.
    Show 2 "Preparing python environment (first run only)..."
    "$PSO2_FILES/pso2tricks" -v >/dev/null || Show 1 "pso2tricks failed to start."
    Show 0 "Python environment ready."
}

En_Finale() {
    echo -e "${GREEN_LINE}${aCOLOUR[1]}"
    echo -e " Prerequisites have been downloaded & installed."
    echo -e " Examples:"
    echo -e "   $PSO2_FILES/pso2tricks --tweaker"
    echo -e "   $PSO2_FILES/pso2tricks --patcher ngs ~/Games/PHANTASYSTARONLINE2_JP/pso2_bin"
    echo -e "   $PSO2_FILES/pso2tricks --help${COLOUR_RESET}"
    echo -e "${GREEN_LINE}${COLOUR_RESET}"
}

###############################################################################
# Setup                                                                       #
###############################################################################

# Step 0: Check OS, we only want linux
Check_OS
Check_Depends

# Step 1: Create pso2_files if needed and check write permissions on it
Write_Check

# Step 2: Download uv
Download_uv

Show 0 "Dependencies downloaded & configured"

# Step 3: Download pso2tricks
Download_pso2tricks
Warm_Cache

# Step 4: Done
En_Finale

exit 0
