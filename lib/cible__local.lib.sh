
REQUIRE modules__resolv

cible__local() {
	local target="$1";shift
	local module="$1";shift
	local method="$1";shift

	local f="$module"
	modules__resolv

	case "$method" in
		([A-Z]*) ;;
		(*) echo >&2 "Warning: method should be uppercase ($method)" ;;
	esac

	(
		. "$f"
		"$method" "$@"
	)
}
