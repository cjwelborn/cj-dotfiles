#!/bin/bash
# This file includes prompts, colors, and possibly other stuff for a
# bash interactive session.
# To use it edit /etc/bash.bashrc (for all users) to include:
#   source bash.extras.interactive.sh
# -Christopher Welborn 8-9-13 (not all pieces are original work)

if [[ -d "/home/cjwelborn" ]]; then
    cjhome="/home/cjwelborn"
elif [[ -d "/home/cj" ]]; then
    cjhome="/home/cj"
elif [[ -d "$HOME" ]]; then
    cjhome=$HOME
elif [[ -n "$USER" ]] && [[ -d "/home/$USER" ]]; then
    cjhome="/home/$USER"
else
    cjhome="/root"
fi

# Log some debug info while loading this script.
if [[ -w "$cjhome" ]]; then
  bashextraslogfile="$cjhome/extras.interactive.log"
else
  echo_safe "No log file to write to."
fi

function bashextraslog {
    # Write to the bash.extras.interactive.log
    if [[ -n "$2" ]]; then
        # label/value pair.
        printf "%-40s: %s\n" "$1" "$2" >> "$bashextraslogfile"
    else
        echo -e "$@" >> "$bashextraslogfile"
    fi
}
echo "Loading ${BASH_SOURCE[0]}, cjhome=$cjhome" > "$bashextraslogfile"

# Set font if using a tty (1-6).
if [[ "$TERM" == "linux" ]]; then
    bashextraslog "Terminal: linux"
    # This is the default font that is used for ttys.
    termfontfile_default="/usr/share/consolefonts/Uni3-Fixed16.psf.gz"
    # This is the font that I want to use.
    termfontfile="/usr/share/consolefonts/Uni3-Terminus16.psf.gz"
    if [[ -e "$termfontfile" ]]; then
        bashextraslog "Setting font to" "$termfontfile"
        setfont "$termfontfile"
    elif [[ -e "$termfontfile_default" ]]; then
        bashextraslog "Setting font to" "$termfontfile_default"
        setfont "$termfontfile_default"
    else
        bashextraslog "No terminal font files found, tried:"
        bashextraslog "    $termfontfile"
        bashextraslog "    $termfontfile_default"
    fi
else
    bashextraslog "Not a 'linux' terminal, no font set."
fi

# Set dir_colors if it exists.
dircolorsfile="$cjhome/.dir_colors"
if [[ -e "$dircolorsfile" ]]; then
    eval "$(dircolors "$dircolorsfile")"
    bashextraslog "dir_colors set from" "$dircolorsfile"
else
    bashextraslog "No .dir_colors found."
fi
unset -v dircolorsfile

# ---------------------------------- COLORS ----------------------------------
# Define some colors first: (SC2034 = Unused vars (they are exported though))

export NOCOLOR=$'\e[0m'
export NC=$NOCOLOR
export black=$'\e[0;30m'
export red=$'\e[0;31m'
export green=$'\e[0;32m'
export yellow=$'\e[0;33m'
export blue=$'\e[0;34m'
export magenta=$'\e[0;35m'
export cyan=$'\e[0;36m'
export white=$'\e[0;37m'
export DARKGRAY=$'\e[1;30m'
export RED=$'\e[1;31m'
export GREEN=$'\e[1;32m'
export YELLOW=$'\e[1;33m'
export BLUE=$'\e[1;34m'
export MAGENTA=$'\e[1;35m'
export CYAN=$'\e[1;36m'
export WHITE=$'\e[1;37m'
export bg_black=$'\e[40m'
export bg_red=$'\e[41m'
export bg_green=$'\e[42m'
export bg_yellow=$'\e[43m'
export bg_blue=$'\e[44m'
export bg_magenta=$'\e[45m'
export bg_cyan=$'\e[46m'
export bg_white=$'\e[47m'
export underlined=$'\e[4m'
bashextraslog "Defined some global colors."
# ------------------------------- LESS COLORS --------------------------------
# Capabilities:
# ks - make the keypad send commands
# ke - make the keypad send digits
# vb - emit visual bell
# mb - start blink
# md - start bold
# me - turn off bold, blink and underline
# so - start standout (reverse video)
# se - stop standout
# us - start underline
# ue - stop underline
#  shellcheck disable=SC2155
function set_less_colors() {
    # Start blink
    export LESS_TERMCAP_mb=$RED
    # Start bold
    export LESS_TERMCAP_md=$blue
    # Start standout.
    export LESS_TERMCAP_so=$'\e[47;1;30m' # Black on white.
    # Start underline
    export LESS_TERMCAP_us=$green

    # Stop blink, bold, and underline.
    export LESS_TERMCAP_me=$NOCOLOR
    # Stop standout.
    export LESS_TERMCAP_se=$NOCOLOR
    # End underline
    export LESS_TERMCAP_ue=$NOCOLOR
}
set_less_colors
unset -f set_less_colors
bashextraslog "Set \`less\` colors."
# ---------------------- FZF Fuzzy Finder keybindings. ----------------------
function fzf_setup {
    local fzf_source="$cjhome/.fzf.bash"
    if [[ ! -f "$fzf_source" ]] || ! hash "$cjhome/clones/fzf/bin/fzf" &>/dev/null; then
        # Missing fzf executable or bash file.
        return 1
    fi
    # Use terminal height - 2, to allow for the box border.
    local fzfpreviewlinecnt=$((${LINES:-$(tput lines)} - 2))
    # If no other highlighter is found, just use cat.
    local highlighter="cat"
    if hash highlight &>/dev/null; then
        # Use the 'highlight' command from apt packages.
        highlighter="highlight -O ansi"
    elif hash ccat &>/dev/null; then
        # Use ccat from https://github.com/welbornprod/ccat
        highlighter="ccat --colors --format terminal"
    fi
    declare -a highlightcmd=(
        "("
        "$highlighter {} ||"
        # Everything must be double escaped, because it is ran through
        # fzf/shell/key-bindings.bash.
        "if [[ \\\$(file {}) =~ text ]]; then"
        "    cat {};"
        "else"
        "    echo 'No preview available for {}.';"
        "fi"
        ") 2>/dev/null | head -n${fzfpreviewlinecnt}"
    )

    export FZF_CTRL_T_OPTS="--preview \"${highlightcmd[*]}\""
    bashextraslog "Loading fzf keybindings from" "$fzf_source"
    # shellcheck source=/home/cj/.fzf.bash
    source "$fzf_source"
    echo_safe "Fzf fuzzy finder available" "Ctrl + T"
    return 0
}
fzf_setup || bashextraslog "No fzf available..."
unset -f fzf_setup

# ------------------------------- PROMPT FUNCTIONS ---------------------------
# Set Hilite Color for 3rd Party Prompts
if [[ "${DISPLAY%%:0*}" != "" ]]; then
    HILIT=$red   # remote machine: prompt will be partly red
else
    HILIT=$cyan  # local machine: prompt will be partly cyan
fi

# This is needed for the simple/default prompts.
if [[ -z "${debian_chroot:-}" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Following simple/default prompt function from original simple/fancy prompts.
function simpleprompt()
{
    # depends on debian_chroot being available:
    # shellcheck disable=SC2154
    unset -v PROMPT_COMMAND
    # Sets the prompt to (chroot name)user@host: workingdir $
    # If debian_chroot is not set, it is not used.
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
}

function defaultprompt()
{
    # depends on debian_chroot being available:
    # shellcheck disable=SC2154
    unset -v PROMPT_COMMAND
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Following 3rd party 'Power Prompt' & 'Fast Prompt' added by Cj
function fastprompt() {
    unset PROMPT_COMMAND
    case $TERM in
        *term | rxvt )
        PS1="${HILIT}[\h]$NOCOLOR \W > \[\033]0;\${TERM} [\u@\h] \w\007\]" ;;
    linux )
        PS1="${HILIT}[\h]$NOCOLOR \W > " ;;
        *)
        PS1="[\h] \W > " ;;
    esac
}

function _powerprompt() {
       # shellcheck disable=SC2034
        LOAD=$(uptime|sed -e "s/.*: \([^,]*\).*/\1/" -e "s/ //g")
}

function powerprompt() {

    PROMPT_COMMAND="_powerprompt"
    case $TERM in
        *term | rxvt  )
            PS1="${HILIT}[\A - \$LOAD]${NOCOLOR}\n[\u@\h \#] \W > \
                 \[\033]0;\${TERM} [\u@\h] \w\007\]" ;;
        linux )
            PS1="${HILIT}[\A - \$LOAD]${NOCOLOR}\n[\u@\h \#] \W > " ;;
        * )
            PS1="[\A - \$LOAD]\n[\u@\h \#] \W > " ;;
    esac
}
powerline_file="$cjhome/powerline-shell.py"
# Powerline-shell prompt.
function _update_powerline_ps1() {
  # Maximum number of directories to show. -Set by Cj.
  # If --cwd-max-depth isn't working, --cwd-only will.
  local pline_maxdepth=3
  # Display style. Patched is fancy, flat is plain, compatible is in between.
  local pline_mode="patched" # patched, compatible, or flat.

  # Final args to use with powerline-shell.
  local pline_args=("--cwd-max-depth" "$pline_maxdepth" "--mode" "$pline_mode" "--shell" "bash")
  # Last command's return code is always the last arg ($?).
  local pline_ps1
  pline_ps1="$("$powerline_file" "${pline_args[@]}" $? 2>/dev/null)"
  export PS1=$pline_ps1
}

function powerlineprompt {
    # Load the powerline prompt.
    export PROMPT_COMMAND="_update_powerline_ps1"
}

# Following prompt created by Cj...
function cjprompt()
{
    unset -v PROMPT_COMMAND
    PS1="${blue}\u${NOCOLOR}:${BLUE}\W ${NOCOLOR}\$ "
}

# Function to list prompts that are available.
function listprompts()
{
    declare -A prompts=(
        ["cjprompt"]="minimal prompt with user:/dir with color."
        ["defaultprompt"]="standard user@host:/dir prompt with color."
        ["fastprompt"]="minimal prompt with [hostname] dir > ."
        ["powerprompt"]="long prompt with extra info like time."
        ["powerlineprompt"]="powerline-shell prompt with icons and info."
        ["simpleprompt"]="standard user@host:/dir prompt without color."

    )
    local promptname
    for promptname in "${!prompts[@]}"; do
        printf "%s%-16s%s: %s%s%s\n" "$blue" "$promptname" "$NOCOLOR" "$green" "${prompts[$promptname]}" "$NOCOLOR"
    done
}


# Use powerline shell prompt if available -------------------------------------
if [[ -x "$powerline_file" ]]; then
    powerlineprompt
    bashextraslog "Using powerline prompt from" "$powerline_file"
else
    # Fall back to cj's prompt where powerline-shell is not available.
    if [[ -e "$powerline_file" ]]; then
        bashextraslog "Fallback to cjprompt, not executable: $powerline_file"
    else
        bashextraslog "Fallback to cjprompt, missing: $powerline_file"
    fi
    cjprompt || {
        simpleprompt
        bashextraslog "Even cj's prompt failed, falling back to simple prompt."
    }
fi

# --------------------------- AUTO-LOADED PROGRAMS ---------------------------

function favor_fortune {
    # Try displaying a fortune filtered by lolcat (rainbow colored),
    # which favors the 'irc_debian_hackers', 'ascii-art', and 'computers'
    # databases.
    # Falls back to no color if lolcat is missing.
    # Falls back to normal distribution if favorites are missing.
    if ! hash fortune &>/dev/null; then
        return 1
    fi
    declare -a filtercmd
    if hash colr &>/dev/null; then
        filtercmd=(colr --truecolor --rainbow)
    elif hash lolcat &>/dev/null; then
        # Filter the fortunes through lolcat.
        filtercmd=(lolcat)
    else
        # Plain output (using cat).
        filtercmd=(cat)
    fi
    local fortunefiles
    fortunefiles=($(find /usr/share/games/fortunes/ -iregex '[^\.]+$'))

    declare -a fortunedbs
    local filepath
    local dbname
    for filepath in "${fortunefiles[@]}"; do
        dbname="${filepath##*/}"
        [[ -z "$dbname" ]] && continue
        fortunedbs+=("$dbname")
    done

    # Favorite fortune dbs, with a percentage showing their chance at display.
    # The rest are split equally.
    # All of them together must not equal 100%, to give the others a chance.
    declare -A fortunefavs
    fortunefavs=(
        ["50%"]="irc_debian_hackers"
        ["25%"]="ascii-art"
        ["15%"]="computers"
    )
    declare -a fortuneargs
    local favorchance
    local favordb
    for favorchance in "${!fortunefavs[@]}"; do
        favordb="${fortunefavs[$favorchance]}"
        if [[ -e "/usr/share/games/fortunes/$favordb" ]]; then
            fortuneargs+=("$favorchance" "$favordb")
            bashextraslog "Found fortune file" "$favordb, set to: $favorchance"
        fi
    done
    fortune "${fortuneargs[@]}" "${fortunedbs[@]}" | "${filtercmd[@]}"

}

# Alias Manager scripts.
aliasmgrfile="/usr/share/aliasmgr/aliasmgr_scripts.sh"
plainaliasfile="$cjhome/bash.alias.sh"
if [[ -f "$aliasmgrfile" ]]; then
    echo ""
    # shellcheck source=/usr/share/aliasmgr/aliasmgr_scripts.sh
    # shellcheck disable=SC1091
    # ..This file doesn't always exist, shellcheck.
    source "$aliasmgrfile"
    echo_safe "Loaded aliasmgr scripts" "$aliasmgrfile"
    bashextraslog "Using aliasmgr scripts" "$aliasmgrfile"
elif [[ -f "$plainaliasfile" ]]; then
    # shellcheck source=/home/cj/bash.alias.sh
    source "$plainaliasfile"
    echo_safe "Loaded plain alias script" "$plainaliasfile"
    bashextraslog "Using plain alias script" "$plainaliasfile"
fi
unset aliasmgrfile
unset plainaliasfile
# Show fortune, 'favor_fortune' will be available globally.
# shellcheck disable=SC2034
while read -r char; do
    printf "-"
done < <(seq 1 "$COLUMNS")
unset char
printf "\n\n"
favor_fortune

# Print cj's todo list.
if ! hash todo &>/dev/null; then
    echo_safe "Can't find the 'todo' app."
    bashextraslog "No \`todo\` app found."
else
    # print todo list
    echo ""
    todo --preview
    bashextraslog "Loaded \`todo\` from" "$(which todo)"
fi

# Setup lesspipe, so the `less` command can handle other file types.
# Another option is to use '$(lessfile)', which processes the entire file
# before displaying it. `lesspipe` views the file DURING processing, using
# pipes. -Cj
if hash lesspipe &>/dev/null; then
    eval "$(lesspipe)"
    bashextraslog "Set up \`lesspipe\`."
else
    bashextraslog "\`lesspipe\` not found, no fancy \`less\` formats."
fi
# Welcome message.
welcomemsg="${BLUE}Bash ${RED}${BASH_VERSION%.*} ${CYAN}Loaded${NC}"
hoststr="${CYAN}$(hostname)${NC}"
ips=($(hostname -I))
ipstr="${RED}${ips[0]}${NC}"
echo -e "\n$welcomemsg  ${BLUE}$(date)${NC}  $hoststr ($ipstr)"
# These vars are not needed globally.
unset -v welcomemsg hoststr ips ipstr

# ---------------------------------- GOODBYE ---------------------------------
Lastdirfile="$cjhome/.cj-lastdir"

# Setup Exit Message
function _exit_handler() {
    save_last_session_dir
    echo -e "\n${RED}Goodbye ${USER:-.}...$NC"
}
# Trap/Set Exit Function
trap _exit_handler EXIT

function save_last_session_dir {
    # Shortcut for `echo "$PWD" > "$Lastdirfile"`
    # This function may be called from somewhere else (another script?).
    if [[ -z "$cjhome" ]] || [[ ! -w "$cjhome" ]]; then
        echo "Unable to write to home dir!: ${cjhome:-No home directory is set.}" 1>&2
        return 1
    fi
    if [[ -v Lastdirfile ]] && [[ -n "$Lastdirfile" ]]; then
        # The file is created if it doesn't exist.
        echo "$PWD" > "$Lastdirfile"
        return 0
    fi
    return 1
}

function get_last_session_dir {
    # Read last saved directory from Lastdirfile and print it.
    local lastdirs
    if [[ -e "$Lastdirfile" ]]; then
        mapfile -t lastdirs < "$Lastdirfile"
        if ((${#lastdirs[@]})); then
            if [[ -d "${lastdirs[0]}" ]]; then
                printf "%s" "${lastdirs[0]}"
                return 0
            fi
            echo -e "\nLast directory is invalid: ${lastdirs[0]}" 1>&2
            return 1

        fi
        echo -e "\nLast directory file was empty: $Lastdirfile"
        return 1
    fi
    # No last dir file.
    return 1
}

function goto_last_session_dir {
    # Read Lastdirfile and cd to the last dir saved.
    # This just runs `cd` if it can't read that file or the file is empty.
    local lastdir
    if ! lastdir="$(get_last_session_dir)"; then
        # No directory to go to.
        cd || return 1
        return 1
    fi
    if [[ -z "$lastdir" ]] || [[ ! -d "$lastdir" ]]; then
        # Empty lastdir.
        cd || return 1
        return 1
    fi
    cd "$lastdir" || return 1
}
# Goto the last session's directory.
goto_last_session_dir || bashextraslog "Failed to goto_last_session_dir."
