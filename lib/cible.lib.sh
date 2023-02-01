
# $target exists
_cible() {
	#### manage targets ####
	if [ -z "$target" ]; then
		msgerror "No target ?!"
		return 1
	fi

	case "$1" in
	(ssh)	(	shift
			REQUIRE via__ssh
			! ${cible_verbose:-false} || echo >&2 "## --- cible($target) via__ssh[$#]: $*"
			via__ssh "$target" "$@"
		)
	;;
	(sshcheck)	shift
		(
			REQUIRE via__ssh
			REQUIRE via__ssh__check
			! ${cible_verbose:-false} || echo >&2 "## --- cible($target) via__ssh__check[$#]: $*"
			via__ssh__check "$target"
		)
	;;
	(eval) 	(
			shift
			! ${cible_verbose:-false} || echo >&2 "## --- cible($target) eval[$#]: $*"
			eval "$@"
		)
	;;
	(*)	(
			local cmd="$1";shift
			! ${cible_verbose:-false} || echo >&2 "## --- cible($target) source_exec($cmd)[$#]: $*"
			. ./"$cmd"
		)
	;;
	esac
	return $?
}

cible_help() {
	local zero__=
	echo 'Usage:'
	echo '       cible <target> [options] path/to/script.sh   [<args...>]'
	echo '       cible <target> [options] sshcheck            [<args...>]'
	echo '       cible <target> [options] ssh                 [<args...>]'
	echo '       cible <target> [options] eval                [<args...>]'
	echo 'Options:'
	echo '   -p <text>|--prefix <text>'
	echo '   -F <text>|--format <text>'
        echo '   -M|--master                   -- [ssh] use ssh ControlMaster feature (enabled by default)'
        echo '   --no-master                   -- [ssh] disable --master'
        echo '   -i|--interactive              -- [ssh] This option allow interactive password to be asked'
	echo '   --no-bootstrap'
	echo '   -v|--verbose'
	echo '   -q|--quiet'
}

cible() {
	local target="$1";shift
	case "$target" in
	(-*) cible_help >&2; return 1 ;;
	esac
	local cible_verbose=false
	local cible_use_prefix='' cible_use_format=''
	local cible_remote_bootstrap='remote.stdin/bootstrap'
        local cible_ssh_use_master=${uplevel_ssh_use_master:-true}
        local cible_ssh_interactive=${uplevel_ssh_interactive:-false}
	[ $# -ne 0 ] || set -- --help
	while [ $# -gt 0 ]; do
		case "$1" in
		(-h|--help|help)
			cible_help >&2
			return 0
		;;
		(-q|--quiet)		cible_verbose=false;;
		(-v|--verbose)		cible_verbose=true;;
		(-M|--master)		cible_ssh_use_master=true;;
		(--no-M|--no-master)	cible_ssh_use_master=false;;
		(-i|--interactive)	cible_ssh_interactive=true;;
		(-F|--format)		cible_use_format="$2";shift;;
		(-p|--prefix)		cible_use_prefix="$2";shift;;
		(--no-bootstrap)	cible_remote_bootstrap='';;
		(--) shift;break;;
		(-*) echo >&2 "ERROR: cible: Invalid option $1"; return 1;;
		(*) break
		esac
		shift
	done

	if [ -n "$cible_ssh_use_master" ]; then
		VIA_SSH_USE_MASTER="$cible_ssh_use_master"
	fi
	if [ -n "$cible_ssh_interactive" ]; then
		VIA_SSH_INTERACTIVE="$cible_ssh_interactive"
	fi

	if [ -z "$cible_use_prefix" ] && [ -z "$cible_use_format" ]; then
		target="$target" _cible "$@"
	else
		target="$target" _cible "$@" |
		while read -r line; do
			printf "${cible_use_format:-%s}"\\n "$(printf %s%s "$cible_use_prefix" "$line")"
		done
	fi
}

