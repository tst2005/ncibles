REQUIRE via__ssh__hostname_with_ssh_options
hostname_with_ssh_options() { via__ssh__hostname_with_ssh_options "$@"; }

via__ssh() {
	local target="$1";shift
	case "$VIA_SSH_INTERACTIVE" in
		(true);;
		(false) set -- -o 'PreferredAuthentications publickey' "$@";;
	esac
	case "$VIA_SSH_USE_MASTER" in
		(true)  set -- -o 'ControlMaster auto' -o 'ControlPath "~/.ssh/.master-%r@%h:%p"' -o 'ControlPersist 60s' "$@";;
		(false) set -- -o 'ControlMaster no'   -o 'ControlPath none'                      -o 'ControlPersist  0s' "$@";;
	esac
	if [ -t 0 ]; then
		set -- -n "$@"
	fi
	ssh $(hostname_with_ssh_options "$target" | grep '' || echo "$target") "$@"
}
