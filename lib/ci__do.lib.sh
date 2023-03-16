REQUIRE ci__local
REQUIRE ci__remote__stdin

ci__do() {
	case "$1" in
	(*local2local/*)  ci__local "$target" "$@" ;;
	(*local2remote/*) ci__local "$target" "$@" ;;
	(*remote.stdin/*) ci__remote__stdin "$target" "$@";;
	(*) echo >&2 "ci__do:ERROR: invalid module path";return 1;;
	esac
}
