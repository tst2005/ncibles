
# $target exists
_cible() {
	#### manage targets ####
	if [ -z "$target" ]; then
		msgerror "No target ?!"
		return 1
	fi

	case "$1" in
	(ssh)	(
			REQUIRE via__ssh
			! ${cible_verbose:-false} || echo >&2 "## --- cible($target) ssh[$#]: $*"
			shift;via__ssh "$target" "$@"
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
			! ${cible_verbose:-false} || echo >&2 "## --- cible($target) exec($cmd)[$#]: $*"
			. ./"$cmd"
		)
	;;
	esac
	return $?
}

cible_help() {
	echo 'Usage: cible <target> [options] ssh|eval|<path> [<args...>]'
	echo '       cible <target> path/to/script.sh   [<args...>]'
	echo '       cible <target> ssh|eval            [<args...>]'
	echo 'Options:'
	echo '   -p <text>|--prefix <text>'
	echo '   --no-bootstrap'
	echo '   -v|--verbose'
	echo '   -q|--quiet'
}

cible() {
	local target="$1";shift
	local cible_verbose=false
	local cible_use_prefix=''
	local cible_remote_bootstrap='remote.stdin/bootstrap'
	[ $# -ne 0 ] || set -- --help
	while [ $# -gt 0 ]; do
		case "$1" in
		(-h|--help|help)
			cible_help >&2
			return 0
		;;
		(-q|--quiet) cible_verbose=false;;
		(-v|--verbose) cible_verbose=true;;
		(-p|--prefix) cible_use_prefix="$2";shift;;
		(--no-bootstrap) cible_remote_bootstrap='';;
		(--) shift;break;;
		(-*) echo >&2 "ERROR: cible: Invalid option $1"; return 1;;
		(*) break
		esac
		shift
	done
	if [ -z "$cible_use_prefix" ]; then
		target="$target" _cible "$@"
	else
		target="$target" _cible "$@" |
		while read -r line; do
			printf %s%s\\n "$cible_use_prefix" "$line"
		done
	fi
}

