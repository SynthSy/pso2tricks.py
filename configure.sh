#!/usr/bin/env bash
# shellcheck disable=SC1090
#
# Auto installer for the lazy
# Setup the required user dependencies to
# execute pso2tricks.py
#
# Downloads the following:
# - virtualenv.pyz python3 web script
# from https://bootstrap.pypa.io/virtualenv.pyz
# - - Allows the creation of a python virtual environment
# so we can install the python library requests
#
# This script will automatically create a virutal
# environment named "myenv" which will be activated
# afterwards, allowing execution of our custom python
# script "pso2tricks.py".
#
# If you have suggestions, feel free to let us know.
#
# pso2tricks.py is licensed under the WTFPL.
clear
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
export DEBIAN_FRONTEND=noninteractive

set -e

###############################################################################
# Globals                                                                     #
###############################################################################

# SYSTEM REQUIREMENTS
readonly PSO2TRICKS_DEPENDS=('wget' 'curl' 'python3', 'flatpak')

UNAME_M="$(uname -m)"
readonly UNAME_M

UNAME_U="$(uname -s)"
readonly UNAME_U

VIRTENV=https://bootstrap.pypa.io/virtualenv.pyz
PSO2TRICKS_URL=https://raw.githubusercontent.com/SynthSy/pso2tricks.py/refs/heads/main/pso2tricks.py

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
readonly GREEN_BULLET=" ${aCOLOUR[0]}-$COLOUR_RESET"
readonly GREEN_SEPARATOR="${aCOLOUR[0]}:$COLOUR_RESET"

###############################################################################
# Helpers                                                                     #
###############################################################################

#######################################
# Custom printing function
# Globals:
#   None
# Arguments:
#   $1 0:OK   1:FAILED  2:INFO  3:NOTICE
#   message
# Returns:
#   None
#######################################

Show() {
    # OK
    if (($1 == 0)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]}  OK  $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    # FAILED
    elif (($1 == 1)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[3]}FAILED$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
        exit 1
    # INFO
    elif (($1 == 2)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[0]} INFO $COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    # NOTICE
    elif (($1 == 3)); then
        echo -e "${aCOLOUR[2]}[$COLOUR_RESET${aCOLOUR[4]}NOTICE$COLOUR_RESET${aCOLOUR[2]}]$COLOUR_RESET $2"
    fi
}

Warn() {
    echo -e "${aCOLOUR[3]}$1$COLOUR_RESET"
}

GreyStart() {
    echo -e "${aCOLOUR[2]}\c"
}

ColorReset() {
    echo -e "$COLOUR_RESET\c"
}

# Clear Terminal
Clear_Term() {

    # Without an input terminal, there is no point in doing this.
    [[ -t 0 ]] || return

    # Printing terminal height - 1 newlines seems to be the fastest method that is compatible with all terminal types.
    lines=$(tput lines) i newlines
    local lines

    for ((i = 1; i < ${lines% *}; i++)); do newlines+='\n'; done
    echo -ne "\e[0m$newlines\e[H"

}

# Check file exists
exist_file() {
    if [ -e "$1" ]; then
        return 1
    else
        return 2
    fi
}

Check_OS() {
    if [[ $UNAME_U == *Linux* ]]; then
        Show 0 "Your System is : $UNAME_U"
    else
        Show 1 "This script is only for Linux."
        exit 1
    fi
}

Write_Check() {
    if [[ -w . ]]; then
      Show 0 "Write permissions are granted for the directory."
    else
      Show 1 "Error: No write permissions in the current directory. Exiting."
      exit 1
    fi
}

Download_Virtual_Env() {
    if [[ -d "$HOME/pso2_files" ]]; then
      cd "$HOME/pso2_files" && curl -fsSOL --output-dir "$HOME/pso2_files" $VIRTENV
      Show 2 "Downloaded to existing directory"
    else
      Show 3 "Could not find existing pso2_files directory, making one now..."
      mkdir "$HOME/pso2_files" && \
      Show 3 "Directory created in $HOME/pso2_files, continuing..." && \
      curl -fsSOL --output-dir "$HOME/pso2_files" $VIRTENV
      Show 0 "Downloaded virtualenv.pyz"
    fi
}

En_Finale() {
    echo -e "${GREEN_LINE}${aCOLOUR[1]}"
    echo -e " Prerequisites have been downloaded & installed"
    echo -e " You may use pso2tricks.py to download &"
    echo -e " install the english patch.${COLOUR_RESET}"
    echo -e "${GREEN_LINE}"
    echo -e "${COLOUR_RESET}"
}

Download_pso2tricks() {
    cd "$HOME/pso2_files" && \
    curl -O -J -s -S -L $PSO2TRICKS_URL
}

###############################################################################
# Setup checks                                                                #
###############################################################################

# Step 0: Check OS, we only want linux
Check_OS

# Step 1: Check if the script has write permissions
Write_Check

# Step 2: Download virtualenv.pyz using curl
Download_Virtual_Env

# Step 3: Create a virtual environment using the downloaded 
# virtualenv.pyz, then activate the virtual environment
(
    cd "$HOME/pso2_files" && \
    python virtualenv.pyz myenv > /dev/null 2>&1 && \

# Step 4: Install the requests library using pip
    "$HOME/pso2_files/myenv/bin/python3" "$HOME/pso2_files/myenv/bin/pip" install --quiet requests
)
Show 0 "Dependencies downloaded & configured"

# Step 5: Download pso2tricks
Download_pso2tricks

# Step 6: Done
En_Finale

cd "$HOME/pso2_files"
exit 0
