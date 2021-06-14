REQUIRE via__ssh__hostname_with_ssh_options
hostname_with_ssh_options() { via__ssh__hostname_with_ssh_options "$@"; }

via__ssh() {
	local target="$1";shift
	set -- -o 'PreferredAuthentications publickey' "$@"
	case "$UNECIBLE_USE_MASTER" in
		(true)  set -- -o 'ControlMaster auto' -o 'ControlPath "~/.ssh/.master-%r@%h:%p"' -o 'ControlPersist 60s' "$@";;
		(false) set -- -o 'ControlMaster no'   -o 'ControlPath none'                      -o 'ControlPersist  0s' "$@";;
	esac
	ssh $(hostname_with_ssh_options "$target" | grep '' || echo "$target") "$@"
}
