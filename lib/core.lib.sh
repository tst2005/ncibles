REQUIRE() {
	#### init
	# consider this module (named "core") as loaded
	[ -n "$NCIBLES_LOADED" ] || NCIBLES_LOADED=core

	while [ $# -gt 0 ]; do
		#echo "debug: ${loadlevel:-0} REQUIRE $1 ..."
		if echo "$NCIBLES_LOADED" | grep -Fwq "$1"; then
			#echo >&2 "debug: ${loadlevel:-0} REQUIRE $1 (already loaded)"
			return 0
		fi

		#### LOAD ####
		NCIBLES_LOADED="$NCIBLES_LOADED"$'\n'"$1"
		loadlevel=$((${loadlevel:-0}+1))
		. "$BASEDIR/lib/$1.lib.sh"
		loadlevel=$(($loadlevel-1))
		#### /LOAD ####

		#echo >&2 "debug: ${loadlevel:-0} REQUIRE $1 loaded."
		shift
	done
}

# ALIAS aaa as bbb
#   will produce:
# bbb() { "aaa" "$@"; }
ALIAS() {
	if [ $# -ne 3 ] || [ "$2" != "as" ]; then
		echo >&2 "ERROR: Usage: ALIAS <orig-name> as <new-name>"
		return 1
	fi
	eval "${3}"'() { "'"$1"'" "$@"; }'
}

