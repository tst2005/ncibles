REQUIRE via__ssh

REQUIRE misc__newuid
newuid() { misc__newuid "$@"; }

via__ssh__check() {
	local target="$1";shift
	local uid="$(newuid)"
	if [ "$(
		via__ssh "$target" -n ${CI_SSH_OPTIONS} "echo $uid"
	)" = "$uid" ]; then
		echo >&2 "ok: sshcheck $target"
	else
		echo >&2 "KO: sshcheck $target"
		return 1
	fi
}
