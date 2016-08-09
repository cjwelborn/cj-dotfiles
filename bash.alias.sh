#!/bin/bash

# Generated by Alias Manager 1.7.6-1
# -Christopher Welborn

# Note to user:
#     If you must edit this file manually please stick to this style:
#         Use tabs, not spaces.
#         No tabs before definitons.
#         Seperate lines for curly braces.
#         Use 1 tab depth for start of code block in functions.
#         Function description is first comment in code block.
#         Alias description is comment right side of alias definition.
#
#     ...if you use a different style it may or may not
#        break the program and I can't help you.

# Aliases:
alias aptfix="sudo apt-get install -f" # try to fix broken packages...
alias aptinstall="sudo apt-get install" # Shortcut to sudo apt-get install
alias apt-get-force-overwrite="sudo apt-get -o Dpkg::Options::='--force-overwrite'" # Use --force-overwrite with any apt-get command.
alias banditgame="sshpass -p '8ZjyCRiBWFYkneahHwxCv3wb2a1ORpYL' ssh bandit13@bandit.labs.overthewire.org" # http://overthewire.org/wargames/bandit
alias bfg="java -jar ~/scripts/tools/bfg-1.12.12.jar" # BFG Repo-Cleaner for git.
alias cjaliases="aliasmgr -pca" # print cjs aliases
alias cjfunctions="aliasmgr -pcf" # print cjs functions
alias clearscreen='echo -e "\033[2J\033[?25l"' # Clears the BASH screen by trickery.
alias colr="python3 -m colr" # Shortcut to python3 -m colr.
alias dirs="dirs -v" # Vertical directory listing for 'dirs', with indexes.
alias distupgrade="sudo apt-get update && sudo apt-get dist-upgrade" # Sudo update and dist-upgrade.
alias echo_path="echo \$PATH | tr ':' '\n'" # Echo $PATH, with newlines.
alias exal="exa -abghHliS" # Run exa with a long, detailed view.
alias greenv="green -vv" # Run green with -vv for more verbosity.
alias grep="grep -E --color=always" # use colors and regex for grep always
alias howdoi="howdoi -c" # use colors for howdoi.
alias idledev="pythondev \$Clones/cpython/Lib/idlelib/idle.py" # Start the cpython dev version Idle
alias kdelogout="qdbus org.kde.ksmserver /KSMServer logout 0 0 2" # logout command for KDE...
alias l="ls -a --color --group-directories-first" # Shortcut for ls (also helpful for my broken keyboard)
alias la="ls -Fa --color" # List all files in dir
alias linuxversion="uname -a" # show current linux kernel info/version
alias ll="ls -alh --group-directories-first --color=always" # Long list dir
alias ls="ls -a --color=always --group-directories-first" # List dir
alias lt="tree -a -C --dirsfirst | more -s" # List dir using tree
alias ltd="tree -a -C -d | more -s" # List directories only, using tree (same as `treed`).
alias mkdir="mkdir -p" # Prevents clobbering files
alias mostcpu="ps aux | head -n1 && ps aux | sort -k 3" # Sort 'ps' list of processes by CPU consumption.
alias mostmemory="ps aux | head -n1 && ps aux | sort -k 4" # Sorts 'ps' list of processes by memory consumption.
alias npminstall="npm install --prefix=\$HOME" # Use npm install with a prefix set to $HOME
alias perlmods="cpan -l | sort" # List all installed perl modules (shortcode for cpan -l)
alias phpi="php5 -a" # Just a shortcut to php5 -a, thats all.
alias pipsearch="pip search" # Search for pypi package by name
alias profilepy3="python3 -m cProfile" # Profile a python 3 script using cProfile
alias profilepy="python -m cProfile" # Profile a python script using cProfile
alias profilepypy="pypy -m cProfile" # Profile a pypy script using cProfile
alias profilestackless="stackless -m cProfile" # Profile a stackless script using cProfile
alias pwd="pwd -P" # show actual directory (not symlink)
alias pykdedocpages='google-chrome "/usr/share/doc/python-kde4-doc/html/index.html"' # Views the documentation pages for PyKDE using chrome.
alias servers="sudo netstat -ltupn" # Show all listening servers on this machine.
alias sshkoding="ssh -v -X vm-0.cjwelborn.koding.kd.io" # SSH into koding.com vm (with XForwarding)
alias temp="which sensors &>/dev/null && sensors -f" # Show temperature for machines with 'sensors' installed.
alias tmux="tmux -2" # Use 256 colors with tmux.
alias treed="tree -a -C -d | more -s" # Shows directory tree, directories only...
alias twistedconsole="python -m twisted.conch.stdio" # Runs twisted console (reactor already running)
alias ubuntuversion="lsb_release -a" # shows current ubuntu distro version/codename
alias wpdb="psql welbornprod_db" # Opens a Postgres shell for welbornprod_db.
alias wpsftp="sftp cjwelborn@cjwelborn.webfactional.com" # Opens SFTP session for welbornprod.com
alias wpssh="ssh -X cjwelborn@cjwelborn.webfactional.com" # Opens SSH session on welbornprod.com

# Functions:
function apache()
{
	# runs /etc/init.d/apache2 with args
	if [[ -z "$1" ]]; then
		echo "apache2 will want an argument."
		return
	fi
	# run apache2 with args
	sudo /etc/init.d/apache2 "$@"
}

function apachelog()
{
	# views apache2 logs (error.log by default)
	# shellcheck disable=SC2154
	if [[ -n "$Logs" ]]; then
		local logdir=$Logs
		local logname="${1:-error}_wp_${2:-site}.log"
	else
		local logdir="/var/log/apache2"
		local logname="${1:-error}.log"
	fi
	local logfile="$logdir/$logname"
	echo "Opening apache log: $logfile"
	cat "$logfile"
}

function aptinstall()
{
	# install apt package by name
	if [[ -z "$1" ]] ; then
		echo "Usage: aptinstall packagename"
	else
		sudo apt-get install "$@"
	fi
}

function argclinic()
{
	# Runs argument clinic on a file.
	if [[ -z "$1" ]]; then
	    echo "usage: argclinic <file.c>"
	    return
	fi
	# shellcheck disable=SC2154
	python3 "$Clones/cpython/Tools/clinic/clinic.py" "$@"
}

function asciimovie()
{
	# Play a movie in mplayer with the ASCII driver...
	if [[ -z "$1" ]]; then
		printf "usage: asciimovie <filename>\n"
		return
	fi
	printf "playing movie in ascii mode: %s" "$1"
	mplayer -vo caca "$1"
}

function ask()
{
	# ask a question
	echo -n "$@" '[y/n] ' ; read ans
	case "$ans" in
		y*|Y*) return 0 ;;
		*) return 1 ;;
	esac
}

function birthday()
{
	date --date="$(stat --printf '%y' /lost+found)"
}

function camrecord()
{
	# record an uncrompressed avi with webcam
	if [[ -z "$1" ]]; then
		echo "Usage: camrecord newfilename.avi"
	else
		mencoder tv:// -tv driver=v4l:width=320:height=240:device=/dev/video0 -nosound -ovc lavc -o "$1"
	fi
}

function cdgodir()
{
	# Change to dir reported by godir.
	if [[ -z "$1" ]]; then
		echo "usage: cdgodir <packagename>"
		echo "see: godir --help"
		return 1
	fi

	local godirname
	godirname="$(godir "$1")"
	if (( $? == 0 )); then
		cd "$godirname"
		return 0
	fi
	return 1

}

function cdsym()
{
	# Cd to actual target directory for symlink.
	cd "$(pwd -P)"
	# This is only here for alias manager. :(
	: :
}

function echo_err()
{
	# Echo to stderr (with escape codes).
	echo -e "$@" 1>&2
	# Alias manager crap.
	: :
}

function echo_failure()
{
	# print a red FAILURE message about 71 columns in
	# all of these were inspired by Fedora's (i think) init.d/functions"
	local colnumber="${1:-71}"
	# move to position
	echo -en "\\033[${colnumber}G"
	# shellcheck disable=SC2154
	echo -en "$red"
	echo -n '['
	echo -en "$RED"
	echo -n 'FAILURE'
	echo -en "$red"
	echo ']'
}

function echo_success()
{
	# print a green 'SUCCESS' msg about 71 columns in
	# all of these were inspired by Fedora's (i think) init.d/functions"
	local colnumber="${1:-71}"
	# move to position
	echo -en "\\033[${colnumber}G"
	# shellcheck disable=SC2154
	echo -en "$green"
	echo -n '['
	echo -en "$LIGHTGREEN"
	echo -n 'SUCCESS'
	echo -en "$green"
	echo ']'

}

function echo_warning()
{
	# print a yellow WARNING msg about 71 columns in
	# all of these were inspired by Fedora's (i think) init.d/functions"
	local colnumber="${1:-71}"
	# move to position
	echo -en "\\033[${colnumber}G"
	# shellcheck disable=SC2154
	echo -en "$lightyellow"
	echo -n '['
	echo -en "$YELLOW"
	echo -n 'WARNING'
	echo -en "$lightyellow"
	echo ']'
}

function fe()
{
	# find file and execute command on it
	local pattern=$1
	shift
	local args=("$@")
	((${#args[@]})) || args=("echo")
	find . -type f -iname "*${pattern}*" -exec "${args[@]}" '{}' ';'
	# Alias manager, force function.
	: :
}

function ff()
{
	# find file
	find . -type f -iname "*${1:-}*" -ls ;
	# Force function for alias manager.
	: :
}

function inetinfo()
{
	# show current internet information
	    echo -e "\nYou are logged on ${RED}$HOST"
	    echo -e "\nAdditionnal information:$NC "
	    uname -a
	    echo -e "\n${RED}Users logged on:$NC "
	    w -h
	    echo -e "\n${RED}Current date :$NC "
	    date
	    echo -e "\n${RED}Machine stats :$NC "
	    uptime
	    echo -e "\n${RED}Memory stats :$NC "
	    free
	    my_ip 2>&-
	    echo -e "\n${RED}Local IP Address :$NC"
	    echo "${MY_IP:-"Not connected"}"
	    echo -e "\n${RED}ISP Address :$NC"
	    echo "${MY_ISP:-"Not connected"}"
	    echo -e "\n${RED}Open connections :$NC "
	    netstat -pan --inet
	    echo
}

function kd()
{
	# change dir and list contents
	if [[ -z "$1" ]] ; then
		echo "Usage: kd directory_name"
	else
		cd "$1"
		pwd -P
		ls -a --group-directories-first --color=always
	fi

}

function mkdircd()
{
	# make dir and cd to it
	# mkdir -p "$@" && eval cd "\"\$$#\""
	if [[ -z "$1" ]] ; then
		echo "Usage: mkdircd DIR"
		return 1
	fi
	if ! mkdir -p "$1" && cd "$1"; then
		echo "Failed to make and cd to dir: $1" 1>&2
		return 1
	fi
	echo "Created $1"
	echo "Moved to $(pwd)"
	return 0
}

function move_to_col()
{
	# Move cursor to a certain column number.
	local colnum="${1-0}"
	echo -en "\\033[${colnum}G"
}

function my_ip()
{
	# set MY_IP variable
	MY_IP=$(/sbin/ifconfig w0 | awk '/inet/ { print $2 } ' | \
	sed -e s/addr://)
	MY_ISP=$(/sbin/ifconfig w0 | awk '/P-t-P/ { print $3 } ' | \
	sed -e s/P-t-P://)
	echo " ip: ${MY_IP}"
	if [[ -n "$MY_ISP" ]]; then
		echo "isp: ${MY_ISP}"
	fi

}

function pip3install()
{
	# install package for python3 using pip (sudo auto-used)
	if [[ -z "$1" ]]; then
		echo "Usage: pip3install <pkgname> [-g | pipargs]"
		echo "Options:"
		echo "    -g,--global  : Install globally."
		echo "    pipargs      : Send any arguments to pip."
		return
	fi

	if [[ -z "$2" ]]; then
		# Install the package under user by default.
		pip3 install "$@" --user
	elif [[ "$2" =~ ^(-g)|(--global)$ ]]; then
		# Install globally.
		sudo pip3 install "$1"
	else
		# Install with user args.
		pip3 install "$@"
	fi
}

function pipall()
{
	# Run all pips with arguments.
	if [[ -z "$1" ]]; then
		echo "Usage: pipall [pip args]"
		return
	fi

	pips=("pip" "pip3" "pip-pypy")
	for pipcmd in "${pips[@]}"
	do
		printf "\nrunning: %s %s\n" "${pipcmd}" "${*}"
		if ! sudo "$pipcmd" "$@"; then
			printf "\n\n%s failed!\n" "$pipcmd $*"
			return
		fi
	done
}

function pipinstall()
{
	# install pip package by name
	if [[ -z "$1" ]]; then
		echo "Usage: pipinstall <pkgname> [-g | pipargs]"
		echo "Options:"
		echo "    -g,--global  : Install globally."
		echo "    pipargs      : Send any arguments to pip."
		return
	fi

	if [[ -z "$2" ]]; then
		# Install the package under user by default.
		pip install "$@" --user
	elif [[ "$2" =~ ^(-g)|(--global)$ ]]; then
		# Install globally.
		sudo pip install "$1"
	else
		# Install with user args.
		pip install "$@"
	fi
}

function pipinstallall()
{
	# Trys to install a package using all known pip versions..
	if [[ -z "$1" ]]; then
		echo "Usage: pipallinstall <packagename>"
		return
	fi

	pips=("pip" "pip3" "pip-pypy")
	for pipcmd in "${pips[@]}"
	do
		printf "\nrunning: %s install %s\n" "$pipcmd" "$1"
		if ! $pipcmd install "$1" --user; then
			printf "\n\n%s failed!\n" "$pipcmd"
			return
		fi
	done

}

function portscan()
{
	# scan simple ports 1-255
	if [[ -z "$1" ]]; then
		echo 'usage: portscan [ip or hostname] [nmap options]'
	else
		nmap "$1" -p1-255
	fi
}

function print_failure()
{
	# display a custom failure message using echo_failure
	echo -e -n "$@"
	echo_failure "$((${COLUMNS:-80} - 10))"
}

function print_status()
{
	# Display a status msg with colored marker (success, failure, warning)
	# using the print_success type functions
	# get type of marker to display (success, failure, warning)
	local statustype="${1:-success}"
	# no message will just print the status marker.
	local statusmsg="${2:- }"


	# display msg using print_ functions...
	case $statustype in
		"success"|"ok"|"s"|"-")
			print_success "$statusmsg" ;;
		"failure"|"fail"|"f"|"error"|"err"|"e"|'!')
			print_failure "$statusmsg" ;;
		"warning"|"warn"|"w"|"?")
			print_warning "$statusmsg" ;;
		*)
			# Default, success.
			print_success "$statusmsg" ;;
	esac
}

function print_success()
{
	# displays a custom success msg using echo_success
	echo -e -n "$@"
	echo_success "$((${COLUMNS:-80} - 10))"
}

function print_warning()
{
	# displays custom warning message using echo_warning
	echo -e -n "$@"
	echo_warning "$((${COLUMNS:-80} - 10))"
}

function pscores()
{
	# Show which cores a process is using (PSR column in ps), by name
	if [[ -z "$1" ]]; then
		echo "Usage: pscoresname <name_or_pid>"
		return
	fi
	local pname
	if ! pname="$(pidname "$1" --pidonly)"; then
		echo_err "Unable to get pid for: $1"
		return 1
	fi
	ps -p "$pname" -L -o command,pid,tid,psr,pcpu
}

function pylite()
{
	# highlite a python file, output to console
	if [[ -z "$1" ]]; then
		echo "usage: pylite_ [pythonfile.py]"
	else
		pygmentize -l python -f terminal -P style=borland -O full "$1"
	fi
}

function pylitegif()
{
	# highlite a python file, output to gif file.
	if [[ -z "$1" ]] || [[ -z "$2" ]]; then
		echo "usage: pylitegif [srcfile.py] [output.gif]"
		return 1
	fi
	pygmentize -l python -f gif -P style=borland -O full -o "$2" "$1"
}

function pylitepng()
{
	# highlite a python file, output to png file.
	if [[ -z "$1" ]] || [[ -z "$2" ]]; then
		echo "usage: pylitepng [srcfile.py] [output.png]"
		return 1
	fi
	pygmentize -l python -f png -P style=borland -O full -o "$2" "$1"
}

function showmyip()
{
	# shows current IP address
	echo "Gathering IP Address..."
	# Setting a global here on purpose.
	MY_IP="$(/sbin/ifconfig w0 | awk '/inet/ { print $2 } ' | \
	sed -e s/addr://)"
	echo " ip: $MY_IP"
}

function sshver()
{
	# connect to ssh server and get version, then disconnect
	telnet "$1" 22 | grep "SSH"
	# Force alias manager to make this a function :(
	: :
}

function switchroot()
{
	# Use the chroot's that are setup.
	defaultname="wheezy_raspbian" # the only chroot setup right now.
	usingname=""
	chrootargs=""

	if [[ -z "$1" ]]; then
		echo "Using default chroot: ${defaultname}"
		usingname=$defaultname
	elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
	    # Show usage.
	    echo "usage: switchroot <name> [other args]"
		return
	fi
	    # Have args.
	    args=("$@")
	    usingname="${args[0]}"
	if [[ "$1" =~ ^- ]]; then
		# args passed without name.
		usingname=$defaultname
		chrootargs=("$@")
	    else
		# name was passed, trim the rest of the args.
	        chrootargs=("${args[@]:1}")
	    fi


	if (( ${#chrootargs[@]} == 0 )); then
	    echo "Opening chroot $usingname..."
	    schroot -c "$usingname"
	else
	    echo "Opening chroot $usingname with args: ${chrootargs[*]}"
	    schroot -c "$usingname" "${chrootargs[@]}"
	fi


}

function symlink()
{
	# create a symbolic link arg2 = arg1
	if [[ -z "$1" ]] ; then
		echo_err "expecting path to linked file. (source)"
		echo_err "usage: symlink sourcefile destfile"
		return 1
	elif [[ -z "$2" ]] ; then
		echo_err "expecting path to link. (destination)"
		echo_err "usage: symlink sourcefile destfile"
		return 1
	fi
	# Create the link
	ln -s "$1" "$2"
}

function tarlist()
{
	# list files in a tar archive...
	if (( $# == 0 )); then
		echo 'usage: tarlist [tarfile.tar]'
		return 1
	fi
	tar -tvf "$@"

}

function weatherday()
{
	# display weather per zipcode
	if [[ -z "$1" ]]; then
		# echo "Usage: weather 90210"
		lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=35501" | grep -A13 'Latest Observation'
	else
		lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=$1" | grep -A13 'Latest Observation'
	fi
}

function weatherweek()
{
	# show weather for the week per zipcode
	if [[ -z "$1" ]] ; then
		# echo "Usage: weatherweek [Your ZipCode]"
		lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=35501" | grep -A30 'Forecast Summary'
	else
		lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=$1" | grep -A30 'Forecast Summary'
	fi
}

function wmswitch()
{
	# switch window managers
	if [[ -z "$1" ]] ; then
		echo "Usage: wmswitch windowmanager"
		echo " Like: wmswitch lightdm"
		return 1
	fi

	sudo dpkg-reconfigure "$1"
}

function wpcd()
{
	# shellcheck disable=SC2154
	# cd to wp development dir if needed.
	if [[ "$PWD" != "$Wp" ]]; then
	    echo "Moving to wp development dir: $Wp"
	    cd "$Wp"
	fi
}

function wpfcgi()
{
	# run welbornprod as fcgi [old]...
	wpcd
	python3 manage.py runfcgi "method=threaded" "host=127.0.0.1" "port=3033" "debug=true" "daemonize=false" "pidfile=fcgi_pid"
}

function wpmemory()
{
	# Shows processes and memory usage for apache.
	# shellcheck disable=SC2009
	ps aux | head -n1 && ps aux | grep 'www-data' | grep -v 'grep'

}

function wpprofile()
{
	# Runs a profile server at 127.0.0.1:8080, data in ~/dump/wp-profile
	if [[ -d /home/cj/dump/wp-profile ]]; then
		echo "Deleting files in ~/dump/wp-profile"
		rm /home/cj/dump/wp-profile/*
	else
	    echo "Creating dir ~/dump/wp-profile"
		mkdir /home/cj/dump/wp-profile
	fi


	wpcd
	echo "Starting server..."
	./manage runprofileserver --kcachegrind "--prof-path=/home/cj/dump/wp-profile" "127.0.0.1:8080"
}

function ziplist()
{
	# list files in a zip file
	if (( $# == 0 )); then
	    echo "Usage: ziplist <filename.zip>"
	    return 1
	fi

	unzip -l "$@"
}

# Exports:
export apache
export apachelog
export aptinstall
export argclinic
export asciimovie
export ask
export birthday
export camrecord
export cdgodir
export cdsym
export echo_err
export echo_failure
export echo_success
export echo_warning
export fe
export ff
export inetinfo
export kd
export mkdircd
export move_to_col
export my_ip
export pip3install
export pipall
export pipinstall
export pipinstallall
export portscan
export print_failure
export print_status
export print_success
export print_warning
export pscores
export pylite
export pylitegif
export pylitepng
export showmyip
export sshver
export switchroot
export symlink
export tarlist
export weatherday
export weatherweek
export wmswitch
export wpcd
export wpfcgi
export wpmemory
export wpprofile
export ziplist
