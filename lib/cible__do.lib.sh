REQUIRE cible__local
REQUIRE cible__remote__stdin

cible__do() {
	case "$1" in
	(*local2local/*)  cible__local "$target" "$@" ;;
	(*local2remote/*) cible__local "$target" "$@" ;;
	(*remote.stdin/*) cible__remote__stdin "$target" "$@";;
	(*) echo >&2 "cible__do:ERROR: invalid module path";return 1;;
	esac
}
