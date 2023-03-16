via__ssh__hostname_with_ssh_options() {
	if [ -f "${NCI_ETCDIR:-./etc}/ssh_hosts" ]; then
		grep '^'"$1"'[[:space:]]\+' "${NCI_ETCDIR:-./etc}/ssh_hosts"|
		cut -d= -f2-
	fi
}
