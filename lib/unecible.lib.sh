
# $target exists
_unecible() {

#	if [ -z "$UNECIBLE_USE_MASTER" ] && [ -n "$opt_use_master" ]; then
#		UNECIBLE_USE_MASTER="$opt_use_master"
#	fi

	#### manage targets ####

	if [ -z "$target" ]; then
		msgerror "No target ?!"
		return 1
	fi

	(
		local cmd="$1";shift
		echo >&2 "# --- unecible($target) exec($cmd)[$#]: $*"
		. ./"$cmd"
	)
	return $?
}

unecible_help() {
	echo "Usage: unecible <target> <path/to/task/script.sh> [<args...>]"
}

unecible() {
	local target="$1";shift
	[ $# -ne 0 ] || set -- --help
	while [ $# -gt 0 ]; do
		case "$1" in
		(-h|--help|help)
			unecible_help >&2
			return 0
		;;
		(--) shift;break;;
		(-*) echo >&2 "Invalid option $1"; return 1;;
		#(exec) break;;
		(*) break
		esac
		shift
	done
	target="$target" _unecible "$@"
}

