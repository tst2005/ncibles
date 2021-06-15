REQUIRE via__ssh
unecible_ssh() { via__ssh "$@"; }

REQUIRE misc__newuid
newuid() { misc__newuid "$@"; }

REQUIRE capture__capturecode
capturecode() { capture__capturecode "$@"; }

REQUIRE unecible__remote__conncheck

REQUIRE modules__resolv

unecible__remote__stdin() {
	local target="$1";shift
	unecible__remote__conncheck "$target"

	local uid="$(newuid)"
	{
		echo "echo '# START $uid'"
		capturecode
		for m in $unecible_remote_bootstrap "$@"; do
			local f="$m"
			modules__resolv
			if [ -f "$f" ]; then
				echo "echo '# $m'"
				echo 'UNECIBLE_MODULE="'"$m"'"'
				cat "$f"
				echo "echo '# /$m'"
			else
				echo >&2 "No such module $m"
				return 1
			fi
		done
		echo "echo '# STOP $uid'"
	} |
	tee "$BASEDIR/run/$target/tmp.sh" | {
		local remotecode='set -e;t="$(mktemp -d)";trap "rm -rf -- \"$t\"" EXIT;cd -- "$t";cat ->tmp.sh;sh tmp.sh;'
		set -- ${UNECIBLE_SSH_OPTIONS}
		unecible_ssh "$target" "$@" "$remotecode"
	} >> "$BASEDIR/run/$target/log"
}

