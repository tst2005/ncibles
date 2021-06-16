REQUIRE via__ssh

REQUIRE misc__newuid
newuid() { misc__newuid "$@"; }

cible__remote__conncheck() {
	local target="$1";shift
	[ -d "$BASEDIR/run/$target" ] || mkdir -- "$BASEDIR/run/$target"
	local uid="$(newuid)"
	if [ "$(
		via__ssh "$target" -n ${UNECIBLE_SSH_OPTIONS} "echo $uid"
	)" = "$uid" ]; then
		echo >&2 "ok: sshcheck $target"
		echo "ok: sshcheck $target" >>  "$BASEDIR/run/$target/log"
	else
		echo >&2 "KO: sshcheck $target"
		echo "KO: sshcheck $target" >>  "$BASEDIR/run/$target/log"
		return 1
	fi
}
