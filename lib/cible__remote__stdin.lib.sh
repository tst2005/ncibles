REQUIRE via__ssh
ALIAS via__ssh as cible_ssh # name also used by modules

REQUIRE misc__newuid
newuid() { misc__newuid "$@"; }

REQUIRE capture__capturecode
capturecode() { capture__capturecode "$@"; }

REQUIRE cible__remote__conncheck

REQUIRE modules__resolv

cible__remote__stdin() {
	local target="$1";shift
	cible__remote__conncheck "$target"

	local uid="$(newuid)"
	{
		echo "echo '# START $uid'"
		capturecode
		for m in $cible_remote_bootstrap "$@"; do
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
		cible_ssh "$target" "$@" "$remotecode"
	} >> "$BASEDIR/run/$target/log"
}

