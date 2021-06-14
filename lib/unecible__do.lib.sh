REQUIRE unecible__local
REQUIRE unecible__remote__stdin

unecible__do() {
	case "$1" in
	(*local2local/*) unecible__local "$target" "$@" ;;
	(*local2remote/*) unecible__local "$target" "$@" ;;
	(*remote.stdin/*) unecible__remote__stdin "$target" "$@";;
	(*) echo >&2 "ERROR";return 1;;
	esac
}
