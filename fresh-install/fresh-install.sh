#!/bin/bash

# My install script for new machines. Currently installs:
#   apt packages, using apt-get (from a list.txt)
#   apt package files, using dpkg (from ./debs/*.deb)
#   remote apt package files, using wget and dpkg (from a list.txt).
#   python 2 packages, using pip2 (from a list.txt) (uses sudo for sys pkgs)
#   python 3 packages, using pip3 (from a list.txt) (uses sudo for sys pkgs)
#   app config files (from github.com/cjwelborn/cj-config)
#   bash config files (from github.com/cjwelborn/cj-dotfiles)
#   ruby gems (from a list.txt)
#   atom packages (from a list.txt)
#
# -Christopher Welborn 05-31-2016
shopt -s dotglob
shopt -s nullglob

# App name should be filename-friendly.
appname="fresh-install"
appversion="0.2.0"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
appdir="${apppath%/*}"

# Apt install command with safer args.
aptinstallcmd="sudo apt-get -y --ignore-missing --no-remove install"

# Packages needed to run this script.
# These should be in $appname-pkgs.txt, but just incase I'll try to install
# them anyway after the initial apt-get commands.
script_depends=("debianutils" "git")

filename_apm="$appdir/$appname-apm-pkgs.txt"
filename_gems="$appdir/$appname-gems.txt"
filename_pkgs="$appdir/$appname-pkgs.txt"
filename_pip2_pkgs="$appdir/$appname-pip2-pkgs.txt"
filename_pip3_pkgs="$appdir/$appname-pip3-pkgs.txt"
filename_remote_debs="$appdir/$appname-remote-debs.txt"
required_files=(
    "$filename_apm"
    "$filename_gems"
    "$filename_pkgs"
    "$filename_pip2_pkgs"
    "$filename_pip3_pkgs"
    "$filename_remote_debs"
)

# Location for third-party deb packages.
debdir="$appdir/debs"

# Any failing command that passes through run_cmd will be stored here.
declare -A failed_cmds

# This can be set with the --debug flag.
debug_mode=0

function check_required_files {
    # Check for at least one required file before continuing.
    debug "Checking for required package list files."
    required_cnt=0
    for requiredfile in "${required_files[@]}"; do
        [[ -e "$requiredfile" ]] && let required_cnt+=1
    done
    if ((required_cnt == 0)); then
        echo_err "Missing all required package list files!"
        for requiredfile in "${required_files[@]}"; do
            echo_err "    $requiredfile"
        done
        return 1
    fi
    if ((required_cnt != ${#required_files[@]})); then
        echo_err "Missing some required package list files,"
        echo_err "...some packages may not be installed."
    fi
    return 0
}

function clone_repo {
    # Clone a repo into a temporary directory, and print the directory.
    # Arguments:
    #   $1 : Repo url.
    #   $2 : Arguments for git.
    local repo=$1
    shift
    local gitargs=("$@")
    if [[ -z "$repo" ]]; then
        echo_err "No repo given to clone_repo!"
        return 1
    fi
    local tmpdir
    tmpdir="$(make_temp_dir)" || return 1
    debug "Cloning repo '$repo' to $tmpdir."
    if ! git clone "${gitargs[@]}" "$repo" "$tmpdir"; then
        echo_err "Failed to clone repo: $repo"
        return 1
    fi
    printf "%s" "$tmpdir"
}

function cmd_exists {
    # Shortcut to which $1 &>/dev/null, with a better message on failure.
    if ! which "$1" &>/dev/null; then
        echo_err "Executable not found: $1"
        return 1
    fi
    return 0
}

function copy_file {
    # Copy a file, unless dry_run is set.
    local src=$1
    local dest=$2
    shift; shift
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file!"
        return 1
    fi
    local msg="cp"
    [[ "${dest//$src}" == "~" ]] && msg="backup"
    if ((dry_run)); then
        status "$msg $*" "$src" "$dest"
    else
        debug_status "$msg $*" "$src" "$dest"
        cp "$@" "$src" "$dest"
    fi
}

function copy_file_sudo {
    # Copy a file using sudo, unless dry_run is set.
    local src=$1
    local dest=$2
    shift; shift
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file_sudo!"
        return 1
    fi
    local msg="sudo cp"
    [[ "${dest//$src}" == "~" ]] && msg="sudo backup"
    if ((dry_run)); then
        status "$msg $*" "$src" "$dest"
    else
        debug_status "$msg $*" "$src" "$dest"
        sudo cp "$@" "$src" "$dest"
    fi
}

function copy_files {
    # Safely copy files from one directory to another.
    # Arguments:
    #   $1 : Source directory.
    #   $2 : Destination directory.
    #   $3 : Blacklist pattern, optional.
    local src=$1
    local dest=$2
    local blacklistpat=$3

    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_files!"
        return 1
    fi
    local dirfiles=("$src"/*)

    if ((${#dirfiles[@]} == 0)); then
        echo_err "No files to install in $repodir."
        return 1
    fi
    local srcfilepath
    local srcfilename

    for srcfilepath in "${dirfiles[@]}"; do
        srcfilename="${srcfilepath##*/}"
        [[ -z "$srcfilename" ]] && continue
        [[ -n "$blacklistpat" ]] && [[ "$srcfilename" =~ $blacklistpat ]] && continue
        if [[ -e "${dest}/$srcfilename" ]]; then
            if [[ -f "$srcfilepath" ]]; then
                if ! copy_file "${home}/${srcfilename}" "${home}/${srcfilename}~"; then
                    echo_err "Failed to backup file: ${home}/${srcfilename}"
                    echo_err "    I will not overwrite the existing file."
                    continue
                fi
            elif [[ -d "$srcfilepath" ]]; then
                if ! copy_file "${home}/${srcfilename}" "${home}/${srcfilename}~" -r; then
                    echo_err "Failed to backup directory: ${home}/${srcfilename}"
                    echo_err "    I will not overwrite the existing directory."
                    continue
                fi
            fi
        fi
        if [[ -f "$srcfilepath" ]]; then
            if ! copy_file "$srcfilepath" "${home}/${srcfilename}"; then
                echo_err "Failed to copy file: ${srcfilepath} -> ${home}/${srcfilename}"
            fi
        elif [[ -d "$srcfilepath" ]]; then
            if ! copy_file "$srcfilepath" "${home}/${srcfilename}" -r; then
                echo_err "Failed to copy directory: ${srcfilepath} -> ${home}/${srcfilename}"
            fi
        else
            echo_err "Unknown file type: $srcfilepath"
            continue
        fi
    done

    return 0
}

function debug {
    # Echo a debug message to stderr if debug_mode is set.
    ((debug_mode)) && echo_err "$@"
}

function debug_status {
    # Print status message about file operations, if debug_mode is set.
    ((debug_mode)) && status "$@"
}

function echo_err {
    # Echo to stderr.
    echo -e "$@" 1>&2
}

function fail {
    # Print a message to stderr and exit with an error status code.
    echo_err "$@"
    exit 1
}

function fail_usage {
    # Print a usage failure message, and exit with an error status code.
    print_usage "$@"
    exit 1
}

function find_apm_packages {
    # List installed apm packages on this machine.
    cmd_exists "apm" || return 1
    debug "Gathering installed apm packages."
    echo "# These are atom package names (apm)."
    echo -e "# These packages will be apm installed by $appscript.\n"
    # List names only, so the latest version is downloaded on install.
    # Using array/loop to remove extra newlines at the end of `apm ls`.
    local names
    names=($(apm ls --bare --installed | cut -d'@' -f1))
    local name
    for name in "${names[@]}"; do
        is_skipped_line "$name" && continue
        printf "%s\n" "$name"
    done
}

function find_packages {
    # List installed packages on this machine.
    local blacklisted=("linux-image" "linux-signed" "nvidia")
    local blacklistpat=""
    for pkgname in "${blacklisted[@]}"; do
        [[ -n "$blacklistpat" ]] && blacklistpat="${blacklistpat}|"
        blacklistpat="${blacklistpat}($pkgname)"
    done
    debug "Gathering installed apt packages ( ignoring" "${blacklisted[@]}" ")."
    echo "# These are apt/debian packages."
    echo -e "# These packages will be apt-get installed by $appscript\n"
    # shellcheck disable=SC2016
    # ...single-quotes are intentional.
    comm -13 \
      <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort) \
      <(comm -23 \
        <(dpkg-query -W -f='${Package}\n' | sed 1d | sort) \
        <(apt-mark showauto | sort) \
      ) | grep -E -v "$blacklistpat"
}

function find_pip {
    # List installed pip packages on this machine.
    # Arguments:
    #   $1 : Pip version (2 or 3).
    local ver="${1:-3}"
    local exe="pip${ver}"
    local exepath
    if ! exepath="$(which "$exe" 2>/dev/null)"; then
        fail "Failed to locate $exe!"
    else
        [[ -n "$exepath" ]] || fail "Failed to locate $exe"
    fi
    debug "Listing pip${ver} packages..."
    local pkgname
    echo "# These are python $ver package names."
    echo "# These packages will be installed with pip${ver} by $appscript."
    echo -e "# Packages marked with * are global packages, and require sudo to install.\n"
    for pkgname in $($exepath list | cut -d' ' -f1); do
        debug "Checking for system/local package: $pkgname"
        if is_system_pip "$ver" "$pkgname"; then
            echo "*${pkgname}"
        else
            echo "$pkgname"
        fi
    done
}

function get_deb_desc {
    # Retrieve a short description for a .deb package.
    local debfmt="\${package} v\${version} : \${description}\n"
    local debdesc
    if ! debdesc="$(dpkg-deb -W --showformat="$debfmt" "$1" 2>/dev/null)"; then
        echo_err "Unable to retrieve version for: $1"
        return 1
    fi
    local debline="${debdesc%%$'\n'*}"
    ((${#debline} > 77)) && debline="${debline:0:77}..."
    printf "%s" "$debline"
}

function get_deb_ver {
    # Retrieve the version number for a .deb package.
    if ! dpkg -f "$1" version 2>/dev/null; then
        echo_err "Unable to retrieve version for: $1"
        return 1
    fi
    return 0
}

function get_debfiles {
    # Print deb files available in ./debs
    if [[ ! -d "$debdir" ]]; then
        echo_err "No debs directory found: $debdir"
        return 1
    fi
    local debfiles=("$debdir"/*.deb)
    if ((${#debfiles[@]} == 0)); then
        echo_err "No .deb files in $debdir."
        return 1
    fi
    local debfile
    for debfile in "${debfiles[@]}"; do
        printf "%s\n" "$debfile"
    done
}

function install_apm_packages {
    # Install apm packages from $appname-apm.txt.
    cmd_exists "apm" || return 1
    local apmnames
    apmnames=($(list_file "$filename_apm")) || return 1
    ((${#apmnames[@]})) || return 1
    local apmname
    local errs=0
    local installcmd
    local installdesc
    for apmname in "${apmnames[@]}"; do
        installcmd="apm install '$apmname'"
        installdesc="Installing apm package: $apmname"
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_apt_depends {
    # Install all script dependencies.
    ((${#script_depends[@]})) || return 1
    local errs=0
    local pkgname
    local installcmd
    local installdesc
    for pkgname in "${script_depends[@]}"; do
        installcmd="$aptinstallcmd '$pkgname'"
        installdesc="Installing script-dependency package: $pkgname"
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_apt_packages {
    # Install packages from $appname-pkgs.txt.
    local pkgnames
    pkgnames=($(list_file "$filename_pkgs")) || return 1;
    ((${#pkgnames[@]})) || return 1
    local errs=0
    local pkgname
    local installcmd
    local installdesc
    for pkgname in "${pkgnames[@]}"; do
        installcmd="$aptinstallcmd '$pkgname'"
        installdesc="Installing apt package: $pkgname"
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_config {
    # Install config files from github.com/cjwelborn/cj-config.git
    local repodir
    if ! repodir="$(clone_repo "https://github.com/cjwelborn/cj-config.git")"; then
        echo_err "Repo clone failed, cannot install config."
        return 1
    else
        debug "Changing to repo directory: $repodir"
        if ! cd "$repodir"; then
            echo_err "Failed to cd into repo: $repodir"
            return 1
        fi
        debug "Updating config submodules..."
        if ! git submodule update --init; then
            echo_err "Failed to update submodules!"
            cd -
            return 1
        fi
        cd -
    fi
    local home="${HOME:-/home/$USER}"
    debug "Copying config files..."
    if ! copy_files "$repodir" "$home" "(.gitmodules)|(README)|(^\.git$)"; then
        echo_err "Failed to copy files: $repodir -> $home"
        return 1
    fi
    if [[ -n "$repodir" ]] && [[ "$repodir" =~ $appname ]] && [[ -e "$repodir" ]]; then
        debug "Removing temporary repo dir: $repodir"
        if ! remove_file_sudo "$repodir" -r; then
            echo_err "Failed to remove temporary dir: $repodir"
            return 1
        fi
    fi
    return 0
}

function install_debfiles {
    # Install all .deb files in $appdir/debs/ (unless dry_run is set).
    local debfiles=($(get_debfiles))
    local debfile
    local errs=0
    local installcmd
    local installdesc
    for debfile in "${debfiles[@]}"; do
        installcmd="sudo dpkg -i '$debfile'"
        installdesc="Installing ${debfile##*/}..."
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_debfiles_remote {
    if [[ ! -e "$filename_remote_debs" ]]; then
        echo_err "No remote deb file list: $filename_remote_debs"
        return 1
    fi
    local dldir
    if ! dldir="$(make_temp_dir)"; then
        echo_err "Unable to create a temporary directory!"
        return 1
    fi
    local deblines
    deblines=($(list_file "$filename_remote_debs")) || return 1
    ((${#deblines[@]})) || return 1
    local debline
    local pkgname
    local pkgurl
    local pkgpath
    local pkgmsgs
    local errs=0
    local installcmd
    local installdesc
    for debline in "${deblines[@]}"; do
        pkgname="${debline%%=*}"
        pkgurl="${debline##*=}"
        if [[ -z "$pkgname" || -z "$pkgurl" || ! "$debline" =~ = ]]; then
            echo_err \
                "Bad config in ${filename_remote_debs}!" \
                "\n    Expecting NAME=URL, got:\n        $debline"
            continue
        fi
        pkgpath="${dldir}/${pkgname}.deb"
        echo -e "Downloading $pkgname from: $pkgurl\n"
        if ! wget "$pkgurl" -O "$pkgpath"; then
            echo_err "Failed to download deb package from: $pkgurl"
            let errs+=1
            continue
        fi
        if [[ ! -e "$pkgpath" ]]; then
            echo_err "No package found after download: $pkgurl"
            let errs+=1
            continue
        fi
        pkgmsgs=("Installing third-party package: ${pkgpath##*/}")
        pkgmsgs+=("$(get_deb_desc "$pkgpath")")
        installcmd="sudo dpkg -i '$pkgpath'"
        installdesc="$(strjoin $'\n' "${pkgmsgs[@]}")"
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    if ! remove_file_sudo "$dldir" -r; then
        echo_err "Failed to remove temporary directory: $dldir"
        let errs+=1
    fi
    return $errs
}

function install_dotfiles {
    # Install dotfiles files from github.com/cjwelborn/cj-dotfiles.git
    local repodir
    if ! repodir="$(clone_repo "https://github.com/cjwelborn/cj-dotfiles.git")"; then
        echo_err "Repo clone failed, cannot install dot files."
        return 1
    fi
    local home="${HOME:-/home/$USER}"
    debug "Copying dot files..."
    if ! copy_files "$repodir" "$home" '('"$appname"')|(README)|(^\.git$)'; then
        echo_err "Failed to copy files: $repodir -> $home"
        return 1
    fi
    if [[ -n "$repodir" ]] && [[ "$repodir" =~ $appname ]] && [[ -e "$repodir" ]]; then
        debug "Removing temporary repo dir: $repodir"
        if ! remove_file_sudo "$repodir" -r; then
            echo_err "Failed to remove temporary dir: $repodir"
            return 1
        fi
    fi
    if [[ -e "${home}/bash.bashrc" ]]; then
        echo "Installing global bashrc."
        if [[ -e /etc/bash.bashrc ]]; then
            echo "Backing up global bashrc."
            copy_file_sudo '/etc/bash.bashrc' '/etc/bash.bashrc~'
        fi
        copy_file_sudo "${home}/bash.bashrc" "/etc/bash.bashrc"
    fi
    local disablefiles=("${home}/.bashrc" "${home}/.profile")
    local disablefile
    for disablefile in "${disablefiles[@]}"; do
        if [[ ! -e "$disablefile" ]]; then
            if [[ -e "${disablefile}~" ]]; then
                debug "Already backed up/disabled: $disablefile"
            else
                debug "Not found, not disabling: $disablefile"
            fi
            continue
        fi
        echo "Backing up existing config file to disable: $disablefile"
        if ! copy_file "$disablefile" "${disablefile}~"; then
            echo_err "Failed to disable existing file: $disablefile\n  It my interfere with new config files..."
            continue
        fi
    done
    return 0
}

function install_gems {
    # Install gem packages found in $appname-gems.txt.
    cmd_exists "gem" || return 1
    local gemnames
    if ! gemnames=($(list_gems)); then
        echo_err "Unable to install gems."
        return 1
    fi
    local gemname
    local errs=0
    for gemname in "${gemnames[@]}"; do
        run_cmd "gem install $gemname" "Installing gem: $gemname" || let errs+=1
    done
    return $errs
}

function install_pip_packages {
    # Install pip packages from $appname-pip${1}.txt.
    local ver="${1:-3}"
    local varname="filename_pip${ver}_pkgs"
    local filename="${!varname}"
    if [[ ! -e "$filename" ]]; then
        echo_err "Cannot install pip${ver} packages, missing ${filename}."
        return 1
    fi
    cmd_exists "pip${ver}" || return 1

    declare -a sudopkgs
    declare -a normalpkgs
    local sudopkgs
    local normalpkgs
    local pkgnames
    pkgnames=($(list_file "$filename")) || return 1
    ((${#pkgnames[@]})) || return 1
    local pkgname
    local sudopat='^\*'
    for pkgname in "${pkgnames[@]}"; do
        if [[ "$pkgname" =~ $sudopat ]]; then
            sudopkgs+=("${pkgname:1}")
        else
            normalpkgs+=("$pkgname")
        fi
    done
    if ((${#sudopkgs[@]} == 0 && ${#normalpkgs[@]} == 0)); then
        echo_err "No pip${ver} packages found in $filename."
        return 1
    fi
    local errs=0
    local installcmd
    local installdesc
    if ((${#sudopkgs[@]})); then
        echo "Installing global pip${ver} packages..."
        local sudopkg

        for sudopkg in "${sudopkgs[@]}"; do
            installcmd="sudo pip${ver} install '$sudopkg'"
            installdesc="Installing global pip${ver} package: $sudopkg"
            run_cmd "$installcmd" "$installdesc" || let errs+=1
        done
    fi
    if ((${#normalpkgs[@]})); then
        echo "Installing local pip${ver} packages..."
        local normalpkg
        for normalpkg in "${normalpkgs[@]}"; do
            installcmd="pip${ver} install '$normalpkg'"
            installdesc="Installing local pip${ver} package: $normalpkg"
            run_cmd "$installcmd" "$installdesc" || let errs+=1
        done
    fi
    return $errs
}

function is_skipped_line {
    # Returns a success exit status if $1 is a line that should be skipped
    # in all config files (comments, blank lines, etc.)
    [[ -z "${1// }" ]] && return 0
    # Regexp for matching comment lines.
    local commentpat='^[ \t]+?#'
    [[ "$1" =~ $commentpat ]] && return 0
    # Regexp for matching whitespace only.
    local whitespacepat='^[ \t]+$'
    [[ "$1" =~ $whitespacepat ]] && return 0
    # Line should not be skipped.
    return 1
}

function is_system_pip {
    # Returns a success exit status if the pip package is found in the
    # global dir.
    local ver="${1:-3}"
    local pkg=$2
    [[ -n "$pkg" ]] || fail "Expected a package name for is_system_pip!"
    local pkgloc
    if ! pkgloc="$(pip"$ver" show "$pkg" | grep Location | cut -d ' ' -f 2)"; then
        # Assume errors are system packages.
        return 0
    fi
    # Assume empty locations are system packages.
    [[ -n "$pkgloc" ]] || return 0
    # Package locations not starting with /home are considered system packages.
    [[ "$pkgloc" =~ ^/home ]] || return 0
    return 1
}

function list_debfiles {
    local debfiles=($(get_debfiles))
    if ((${#debfiles[@]} == 0)); then
        echo_err "No deb files to list!"
        return 1
    fi
    local debfile
    echo -e "\nLocal debian packages:"
    for debfile in "${debfiles[@]}"; do
        printf "\n%s\n    %s\n" "$debfile" "$(get_deb_desc "$debfile")"
    done
}

function list_debfiles_remote {
    # List third-party deb files from $appname-remote_debs.txt
    local deblines
    if ! mapfile -t deblines <"$filename_remote_debs"; then
        echo_err "Failed to read remote deb file list: $filename_remote_debs"
        return 1
    fi
    local debline
    local pkgname
    local pkgurl
    echo -e "\nRemote debian packages:"
    for debline in "${deblines[@]}"; do
        is_skipped_line "$debline" && continue
        pkgname="${debline%%=*}"
        pkgurl="${debline##*=}"
        if [[ -z "$pkgname" || -z "$pkgurl" || ! "$debline" =~ = ]]; then
            echo_err \
                "Bad config in ${filename_remote_debs}!" \
                "\n    Expecting NAME=URL, got:\n        $debline"
            continue
        fi
        printf "\n%-20s: %s\n" "$pkgname" "$pkgurl"
    done
}

function list_failures {
    # List any failed commands in $failed_cmds[@].
    # Returns a success status code if there are failures.
    ((${#failed_cmds[@]})) || return 1
    echo -e "\nFailed commands (${#failed_cmds[@]}):"
    local cmd
    for cmd in "${!failed_cmds[@]}"; do
        printf "\n    Failed: %s\n        %s\n" "${failed_cmds[$cmd]}" "$cmd"
    done
    return 0
}

function list_file {
    # List all names from one of the $appname-*.txt lists.
    if [[  ! -e "$1" ]]; then
        echo_err "No list file found: $1"
        return 1
    fi
    local lines
    if ! mapfile -t lines <"$1"; then
        echo_err "Unable to read from: $1"
        return 1
    fi
    if ((${#lines[@]} == 0)); then
        echo_err "List is empty: $1"
        return 1
    fi
    local line
    for line in "${lines[@]}"; do
        is_skipped_line "$line" && continue
        printf "%s\n" "$line"
    done
}

function make_temp_dir {
    # Make a temporary directory and print it's path.
    local tmproot="/tmp"
    if ! mktemp -d -p "$tmproot" "${appname// /-}.XXX"; then
        echo_err "Unable to create a temporary directory in ${tmproot}!"
        return 1
    fi
    return 0
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Usage:
        $appscript -h | -v
        $appscript [-f2] [-f3] [-fp] [-D]
        $appscript [-l] [-l2] [-l3] [-ld] [-lg] [-D]
        $appscript [-a] [-ap] [-c] [-f] [-g] [-p] [-p2] [-p3] [-D]

    Options:
        -a,--apt            : Install apt packages.
        -ap,--apm           : Install apm packages.
        -c,--config         : Install config from cj-config repo.
        -D,--debug          : Print some debug info while running.
        -d,--dryrun         : Don't do anything, just print the commands.
                              Files will be downloaded to a temporary
                              directory, but deleted soon after (or at least
                              on reboot).
                              Nothing will be installed to the system.
        -f,--dotfiles       : Install dot files from cj-dotfiles repo.
        -f2,--findpip2      : List installed pip 2.7 packages on this machine.
                              Used to build $filename_pip2_pkgs.
        -f3,--findpip3      : List installed pip 3 packages on this machine.
                              Used to build $filename_pip3_pkgs.
        -fa,--findapm       : List installed apm packages on this machine.
                              Used to build $filename_apm.
        -fp,--findpackages  : List installed packages on this machine.
                              Used to build $filename_pkgs.
        -g,--gems           : Install ruby gem packages.
        -h,--help           : Show this message.
        -l,--list           : List apt packages in $filename_pkgs.
        -l2,--listpip2      : List pip2 packages in $filename_pip2_pkgs.
        -l3,--listpip3      : List pip3 packages in $filename_pip3_pkgs.
        -la,--listapm       : List apm packages in $filename_apm.
        -ld,--listdebs      : List all .deb files in ./debs, and remote
                              packages in $filename_remote_debs.
        -lg,--listgems      : List gem package names in $filename_gems.
        -p,--debfiles       : Install ./debs/*.deb packages.
        -p2,--pip2          : Install pip2 packages.
        -p3,--pip3          : Install pip3 packages.
        -v,--version        : Show $appname version and exit.
    "
}

function remove_file {
    # Remove a file/dir, and print a status message about it.
    local file=$1
    if [[ -z "$file" ]]; then
        echo_err "Expected \$file for remove_file!"
        return 1
    fi
    shift
    # Temp files (with the appname in them) are still removed during dry runs.
    if ((dry_run)) && [[ ! "$file" =~ $appname ]]; then
        debug_status "rm $*" "$file"
        return 0
    fi

    status "rm $*" "$file"
    rm "$@" "$file"
}

function remove_file_sudo {
    # Remove a file/dir, and print a status message about it.
    local file=$1
    if [[ -z "$file" ]]; then
        echo_err "Expected \$file for remove_file!"
        return 1
    fi
    shift
    # Temp files (with the appname in them) are still removed during dry runs.
    if ((dry_run)) && [[ ! "$file" =~ $appname ]]; then
        debug_status "rm $*" "$file"
        return 0
    fi
    status "sudo rm $*" "$file"
    sudo rm "$@" "$file"
}

function run_cmd {
    # Run a command, unless dry_run is set (then just print it).
    local cmd=$1
    if [[ -z "${cmd// }" ]]; then
        echo_err "run_cmd: No command to run. ${2:-No description either.}"
        return 1
    fi

    local desc="${2:-Running $1}"
    ((${#desc} > 80)) && desc="${desc:0:80}..."
    echo -e "\n$desc"
    if ((dry_run)); then
        echo "    $cmd"
    else
        # Run command and add it to failed_cmds if it fails.
        eval "$cmd" || failed_cmds[$cmd]=$2
    fi
}

function status {
    # Print a message about a file/directory operation.
    # Arguments:
    #   $1 : Operation (BackUp, Copy File, Copy Dir)
    #   $2 : File 1
    #   $3 : File 2
    printf "%-15s: %-55s\n" "$1" "$2"
    if [[ -n "$3" ]]; then
        printf "%15s: %s\n" "->" "$3"
    else
        printf "\n"
    fi
}

function strjoin {
    local IFS="$1"
    shift
    echo "$*"
}

# Switches for script actions, set by arg parsing.
declare -a nonflags
dry_run=0
do_all=1
do_apm=0
do_apt=0
do_config=0
do_debfiles=0
do_dotfiles=0
do_find=0
do_findapm=0
do_findpackages=0
do_findpip2=0
do_findpip3=0
do_gems=0
do_listing=0
do_list=0
do_listapm=0
do_listdebs=0
do_listgems=0
do_listpip2=0
do_listpip3=0
do_pip2=0
do_pip3=0

for arg; do
    case "$arg" in
        "-a"|"--apt" )
            do_apt=1
            do_all=0
            ;;
        "-ap"|"--apm" )
            do_apm=1
            do_all=0
            ;;
        "-c"|"--config" )
            do_config=1
            do_all=0
            ;;
        "-d"|"--dryrun" )
            dry_run=1
            ;;
        "-D"|"--debug" )
            debug_mode=1
            ;;
        "-f"|"--dotfiles" )
            do_dotfiles=1
            do_all=0
            ;;
        "-f2"|"--findpip2" )
            do_find=1
            do_findpip2=1
            ;;
        "-f3"|"--findpip3" )
            do_find=1
            do_findpip3=1
            ;;
        "-fa"|"--findapm" )
            do_find=1
            do_findapm=1
            ;;
        "-fp"|"--findpackages" )
            do_find=1
            do_findpackages=1
            ;;
        "-g"|"--gems" )
            do_gems=1
            do_all=0
            ;;
        "-h"|"--help" )
            print_usage ""
            exit 0
            ;;
        "-l"|"--list" )
            do_listing=1
            do_list=1
            ;;
        "-l2"|"--listpip2" )
            do_listing=1
            do_listpip2=1
            ;;
        "-l3"|"--listpip3" )
            do_listing=1
            do_listpip3=1
            ;;
        "-la"|"--listapm" )
            do_listing=1
            do_listapm=1
            ;;
        "-lg"|"--listgems" )
            do_listing=1
            do_listgems=1
            ;;
        "-ld"|"--listdebs" )
            do_listing=1
            do_listdebs=1
            ;;
        "-p"|"--debfiles" )
            do_debfiles=1
            do_all=0
            ;;
        "-p2"|"--pip2" )
            do_pip2=1
            do_all=0
            ;;
        "-p3"|"--pip3" )
            do_pip3=1
            do_all=0
            ;;
        "-v"|"--version" )
            echo -e "$appname v. $appversion\n"
            exit 0
            ;;
        -*)
            fail_usage "Unknown flag argument: $arg"
            ;;
        *)
            nonflags+=("$arg")
    esac
done

if ((do_find)); then
    ((do_findapm)) && {
        find_apm_packages || echo_err "Failed to find apm packages."
    }
    ((do_findpackages)) && {
        find_packages || echo_err "Failed to find apt packages."
    }
    ((do_findpip2)) && {
        find_pip "2" || echo_err "Failed to find pip2 packages."
    }
    ((do_findpip3)) && {
        find_pip "3" || echo_err "Failed to find pip3 packages."
    }

    list_failures && exit 1
    exit
elif ((do_listing)); then
    ((do_list)) && {
        list_file "$filename_pkgs" || echo_err "Failed to list apt packages."
    }
    ((do_listapm)) && {
        list_file "$filename_apm" || echo_err "Failed to list apm packages."
    }
    ((do_listdebs)) && {
        list_debfiles || echo_err "Failed to list .deb files."
        list_debfiles_remote || echo_err "Failed to list remote .deb files."
    }
    ((do_listgems)) && {
        list_file "$filename_gems" || echo_err "Failed to list gems."
    }
    ((do_listpip2)) && {
        list_file "$filename_pip2_pkgs" || echo_err "Failed to list pip2 packages."
    }
    ((do_listpip3)) && {
        list_file "$filename_pip3_pkgs" || echo_err "Failed to list pip3 packages."
    }

    list_failures && exit 1
    exit
fi

# Make sure we have at least one package list to work with.
check_required_files || exit 1

# System apt packages.
if ((do_all || do_apt)); then
    run_cmd "sudo apt-get update" "Upgrading the packages list..."
    install_apt_packages || echo_err "Failed to install some apt packages ($?)\n    ...this may be okay though."
    install_apt_depends || echo_err "Failed to install some script dependencies ($?)\n    ...future installs may fail."
fi
# Local/remote apt packages.
if ((do_all || do_debfiles)); then
    install_debfiles || echo_err "Failed to install third-party deb packages (~$?)!"
    install_debfiles_remote || echo_err "Failed to install remote third-party deb packages (~$?)!"
fi
# Pip2 packages.
if ((do_all || do_pip2)); then
    install_pip_packages "2" || echo_err "Failed to install some pip2 packages ($?)\n    ...this may be okay though."
fi
# Pip3 packages.
if ((do_all || do_pip3)); then
    install_pip_packages "3" || echo_err "Failed to install some pip3 packages ($?)\n    ...this may be okay though."
fi
# App config files.
if ((do_all || do_config)); then
    install_config || echo_err "Failed to install config files!"
fi
# Bash config/dotfiles.
if ((do_all || do_dotfiles)); then
    install_dotfiles || echo_err "Failed to install dot files!"
fi
# Ruby-gems
if ((do_all || do_gems)); then
    install_gems || echo_err "Failed to install some gem files ($?)!"
fi
# Atom packages
if ((do_all || do_apm)); then
    install_apm_packages || echo_err "Failed to install some apm packages ($?)!"
fi

list_failures && exit 1
exit
