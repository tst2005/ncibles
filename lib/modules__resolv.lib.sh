REQUIRE modules__resolv
modules__resolv() {
	case "$f" in
		("") echo >&2 "TODO/FIXME/FILLME: completion list in modules/**.sh";return 1 ;;
		(/*) f="$1";;
		(./modules/*|modules/*)
			f="$BASEDIR/$f"
			if [ ! -f "$f" ] && [ -f "$f.sh" ]; then
				f="$f.sh"
			fi
		;;
		(*)
			f="$BASEDIR/modules/$f"
			if [ ! -f "$f" ] && [ -f "$f.sh" ]; then
				f="$f.sh"
			fi
		;;
	esac
	if [ ! -f "$f" ]; then
		echo >&2 "No such file $f"
		return 1
	fi
}
