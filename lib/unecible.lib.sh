
# $target exists
_unecible() {
	#### manage targets ####
	if [ -z "$target" ]; then
		msgerror "No target ?!"
		return 1
	fi

	case "$1" in
	(ssh)	(
			REQUIRE via__ssh
			! ${unecible_verbose:-false} || echo >&2 "## --- unecible($target) ssh[$#]: $*"
			shift;via__ssh "$target" "$@"
		)
	;;
	(eval) 	(
			shift
			! ${unecible_verbose:-false} || echo >&2 "## --- unecible($target) eval[$#]: $*"
			eval "$@"
		)
	;;
	(*)	(
			local cmd="$1";shift
			! ${unecible_verbose:-false} || echo >&2 "## --- unecible($target) exec($cmd)[$#]: $*"
			. ./"$cmd"
		)
	;;
	esac
	return $?
}

unecible_help() {
	echo 'Usage: unecible <target> [options] ssh|eval|<path> [<args...>]'
	echo '       unecible <target> path/to/script.sh   [<args...>]'
	echo '       unecible <target> ssh|eval            [<args...>]'
	echo 'Options:'
	echo '   -p <text>|--prefix <text>'
	echo '   --no-bootstrap'
	echo '   -v|--verbose'
	echo '   -q|--quiet'
}

unecible() {
	local target="$1";shift
	local unecible_verbose=false
	local unecible_use_prefix=''
	local unecible_remote_bootstrap='remote.stdin/bootstrap'
	[ $# -ne 0 ] || set -- --help
	while [ $# -gt 0 ]; do
		case "$1" in
		(-h|--help|help)
			unecible_help >&2
			return 0
		;;
		(-q|--quiet) unecible_verbose=false;;
		(-v|--verbose) unecible_verbose=true;;
		(-p|--prefix) unecible_use_prefix="$2";shift;;
		(--no-bootstrap) unecible_remote_bootstrap='';;
		(--) shift;break;;
		(-*) echo >&2 "ERROR: unecible: Invalid option $1"; return 1;;
		(*) break
		esac
		shift
	done
	if [ -z "$unecible_use_prefix" ]; then
		target="$target" _unecible "$@"
	else
		target="$target" _unecible "$@" |
		while read -r line; do
			printf %s%s\\n "$unecible_use_prefix" "$line"
		done
	fi
}

