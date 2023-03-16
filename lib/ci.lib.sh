
# $target exists
_ci() {
	#### manage targets ####
	if [ -z "$target" ]; then
		msgerror "No target ?!"
		return 1
	fi

	case "$1" in
	(ssh)	(	shift
			REQUIRE via__ssh
			! ${ci_verbose:-false} || echo >&2 "## --- ci($target) via__ssh[$#]: $*"
			via__ssh "$target" "$@"
		)
	;;
	(sshcheck)	shift
		(
			REQUIRE via__ssh
			REQUIRE via__ssh__check
			! ${ci_verbose:-false} || echo >&2 "## --- ci($target) via__ssh__check[$#]: $*"
			via__ssh__check "$target"
		)
	;;
	(eval) 	(
			shift
			! ${ci_verbose:-false} || echo >&2 "## --- ci($target) eval[$#]: $*"
			eval "$@"
		)
	;;
	(*)	(
			local cmd="$1";shift
			! ${ci_verbose:-false} || echo >&2 "## --- ci($target) source_exec($cmd)[$#]: $*"
			. ./"$cmd"
		)
	;;
	esac
	return $?
}

ci_help() {
	local zero__=
	echo 'Usage:'
	echo '       ci <target> [options] path/to/script.sh   [<args...>]'
	echo '       ci <target> [options] sshcheck            [<args...>]'
	echo '       ci <target> [options] ssh                 [<args...>]'
	echo '       ci <target> [options] eval                [<args...>]'
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

ci() {
	local target="$1";shift
	case "$target" in
	(-*) ci_help >&2; return 1 ;;
	esac
	local ci_verbose=false
	local ci_use_prefix='' ci_use_format=''
	local ci_remote_bootstrap='remote.stdin/bootstrap'
        local ci_ssh_use_master=${uplevel_ssh_use_master:-true}
        local ci_ssh_interactive=${uplevel_ssh_interactive:-false}
	[ $# -ne 0 ] || set -- --help
	while [ $# -gt 0 ]; do
		case "$1" in
		(-h|--help|help)
			ci_help >&2
			return 0
		;;
		(-q|--quiet)		ci_verbose=false;;
		(-v|--verbose)		ci_verbose=true;;
		(-M|--master)		ci_ssh_use_master=true;;
		(--no-M|--no-master)	ci_ssh_use_master=false;;
		(-i|--interactive)	ci_ssh_interactive=true;;
		(-F|--format)		ci_use_format="$2";shift;;
		(-p|--prefix)		ci_use_prefix="$2";shift;;
		(--no-bootstrap)	ci_remote_bootstrap='';;
		(--) shift;break;;
		(-*) echo >&2 "ERROR: ci: Invalid option $1"; return 1;;
		(*) break
		esac
		shift
	done

	if [ -n "$ci_ssh_use_master" ]; then
		VIA_SSH_USE_MASTER="$ci_ssh_use_master"
	fi
	if [ -n "$ci_ssh_interactive" ]; then
		VIA_SSH_INTERACTIVE="$ci_ssh_interactive"
	fi

	if [ -z "$ci_use_prefix" ] && [ -z "$ci_use_format" ]; then
		target="$target" _ci "$@"
	else
		target="$target" _ci "$@" |
		while read -r line; do
			printf "${ci_use_format:-%s}"\\n "$(printf %s%s "$ci_use_prefix" "$line")"
		done
	fi
}

