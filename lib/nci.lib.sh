
# usefull to check valid/invalid hostname
REQUIRE via__ssh__hostname_with_ssh_options
hostname_with_ssh_options() { via__ssh__hostname_with_ssh_options "$@"; }


msgerror() {	local r=$?; echo >&2 "$0:ERROR: $1";	return $r; }
msgwarning() {	local r=$?; echo >&2 "$0:Warning: $1";	return $r; }

# Deals with new TLD like .forum ("host forum" equals "host com" or "host fr")
validhost() {
	host "$1" >/dev/null 2>&1 && { host "$1" | grep -q ''; }
}


nci_help() {
	local zero___="$(basename "$0")"
	echo 'Usage: '"$0"' [<option>] for <hostname>|@<groupname> [ci ... \;] [exec|ssh ... {} ... \;]'
	echo 'Options:'
	echo '   --allow-invalid-host          -- do not check host'
	echo '   --master                      -- [ssh] use ssh ControlMaster feature (use by default for '"$zero__"')'
	echo '   --no-master                   -- [ssh] disable --master'
	echo '   -i|--interactive              -- [ssh] This option allow interactive password to be asked'
	echo '   -q|--quiet                    -- do not show name for each target'
	echo '   -v|--verbose                  -- opposit of --quiet (default: --verbose)'
	echo
	echo 'Targets selection:'
	echo '   for  <hostname>               -- add one target'
	echo '   for @<groupname>              -- add a group of targets (see etc/groups/NAME.hosts)'
	echo
	echo 'Actions:'
	echo '   exec ... {} ... \;            -- execute the argument like the find -exec syntax'
	echo 'Alias: (Note: the target is added as first ci argument)'
	echo '   ci                          <-> exec ci {}'
	echo '   ssh        <-> ci ssh       <-> exec ci {} ssh'
	echo '   sshcheck   <-> ci sshcheck  <-> exec ci {} sshcheck'
	echo
	echo 'Sample:'
	echo '   nci for ... exec echo ". {}" \;'
	echo '   nci for ... ssh -n root@{} "id -a;uptime" \;'
	echo '   nci for ... ci ./tasks/uptime.sh \;'
	echo '   nci for ... ci ./tasks/checkaccount.sh email@example.net \;'
}

nci_groupname_list() {
	(
		cd "${NCI_ETCDIR:-./etc}/groups/" &&
		for g in *".hosts"; do
			echo "@${g%.*}"
		done
	)
}

posix_replace() {
	local from="$1";shift
	local to="$1";shift
	local data="$1";shift
	case "$from" in (*,*) return 1;; esac
	case "$to" in (*,*) return 1;; esac
	printf %s "$data" | sed -e 's,'"$from"','"$to"',g'
}

posix_replace_foreach_args__code() {
	echo 'for a in "$@"; do set -- "$@" "$(posix_replace "'"$1"'" "'"$2"'" "$a")";shift;done'
}

#set -- a b "A {}/Z/{}/" c d
#eval "$(posix_replace_in_all_args__code "{}" "$target")"

nci_exec() {

	# search where is the next ';' argument
	local n=$((1+$#-$( while [ $# -gt 0 ] && [ "$1" != ';' ]; do shift; done; echo $# ) ))
	if [ $n -gt $# ]; then
		echo >&2 "ERROR: nci: exec syntax: missing \\; argument in the command line"
		return 1
	fi
	(
		rskip=1 # remove the last argument (";")
		eval "set --$(printf \ \"\${%s}\" $(seq 1 $(($n-$rskip)) ))"
		eval "$(posix_replace_foreach_args__code "{}" "$target")"
		"$@"
	)
	# return the $n to the parent
	echo $n >&3
}

nci() {
	local TARGETS=''
	local allow_invalid_host=false
	local opt_ssh_use_master=true
	local opt_ssh_interactive=false
	local opt_quiet=false
	[ $# -ne 0 ] || set -- --help
	while [ $# -gt 0 ]; do
		case "$1" in
		(-h|--help|help)
			nci_help >&2
			return 0
		;;
		(-v|--verbose) opt_quiet=false;;
		(-q|--quiet) opt_quiet=true;;
		(-M|--master) opt_ssh_use_master=true;;
		(--no-M|--no-master) opt_ssh_use_master=false;;
		(-i|--interactive) opt_ssh_interactive=true;;
		(--allow-invalid-host) allow_invalid_host=true;;
		(--) shift;break;;
		(for)
			case "$2" in
			## Show group completion list
			(""|@)
				nci_groupname_list ' - ' >&2;
				return 1
			;;
			(@*)	## Add a group host
				local f="${NCI_ETCDIR:-./etc}/groups/${2#@}.hosts"
				if [ ! -f "$f" ]; then
					msgerror "No such group $2 ($f)"
					return 1
				fi
				TARGETS="$TARGETS $2";shift
			;;
			(*)	## Add a specific host
				if ! ${allow_invalid_host:-false} && ! validhost "$2" && [ -z "$(hostname_with_ssh_options "$2")" ]; then
					msgerror "Invalid host $2"
					return 1
				fi
				TARGETS="$TARGETS $2";shift
			;;
			esac
		;;
		(-*) echo >&2 "Invalid option $1"; return 1;;
		(*) break
		esac
		shift
	done

	if [ -z "$VIA_SSH_USE_MASTER" ] && [ -n "$opt_ssh_use_master" ]; then
		VIA_SSH_USE_MASTER="$opt_ssh_use_master"
	fi
	if [ -z "$VIA_SSH_INTERACTIVE" ] && [ -n "$opt_ssh_interactive" ]; then
		VIA_SSH_INTERACTIVE="$opt_ssh_interactive"
	fi

#### manage targets ####

	if [ -z "$TARGETS" ]; then
		msgerror "No target ?!"
		return 1
	fi

	tmp=$(mktemp); tmp2=$(mktemp)
	trap "rm -f '$tmp' '$tmp2'" EXIT

	for t in $TARGETS; do
		case "$t" in
		(@*)
			local f="${NCI_ETCDIR:-./etc}/groups/${t#@}.hosts"
			if [ ! -f "$f" ]; then
				echo >&2 "No such group named ${t#@}"
				return 1
			fi
			cat "$f" >> "$tmp"
		;;
		(*)
			echo "$t" >> "$tmp"
		;;
		esac
	done
	grep -v '^#' "$tmp" | sort -u > "$tmp2"
	cat "$tmp2" > "$tmp"
	> "$tmp2"
#FIXME: arriver a garder l'ordre original (1er trouvé 1er gardé, 2eme trouvé=eliminé)

	# list all targets
	if [ $# -eq 0 ]; then
		cat -- "$tmp"
		return 0
	fi

#### run actions ####

	if [ $# -gt 0 ]; then
		local v
		eval 'v="${'"$#"'}"'
		if [ "$v" != \; ]; then
			set -- "$@" \;
		fi
	fi

	while read -r target _; do
		${opt_quiet:-false} || echo >&2 "# ---  $target  --- #"
		(
		while [ $# -gt 0 ]; do
			case "$1" in
			(ci) shift
				REQUIRE ci
				set -- exec ci "{}" "$@"
				continue
			;;
			(ssh|sshcheck)
				set -- ci "$@"
				continue
			;;
			(exec) shift
				exec 3<> "$tmp2"
				nci_exec "$@"
				exec 3>&-
				local n=$(cat -- "$tmp2")
				shift $n
			;;
			(*) echo >&2 "nci: ERROR: Invalid command. Expected ci|ssh|exec, got $1"; return 1;;
			esac
		done
		)
		${opt_quiet:-false} || echo >&2 "# --- /$target  --- #"
		${opt_quiet:-false} || echo
	done < "$tmp"
}

