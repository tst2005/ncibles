
base16decode_lua() {
	tr -d -c '0-9a-fA-F' |
	lua -e '
		local _byte_from_hex = function(x) return string.char(tonumber(x, 16)) end
		local from_hex = function(s) return (s:gsub("[^0-9a-fA-f]",""):gsub("(..)", _byte_from_hex)) end
		io.stdout:write(from_hex(io.stdin:read("*a")))
	'
}
base16decode_printf() { while read -r line; do printf "$(printf '\\x%s' $line)"; done; }
base8decode_printf() { while read -r line; do printf "$(printf '\\%s' $line)"; done; }

base16decode_xxd() { xxd -r -p; }

base64decode() {
	base64 -di
}

base8decode() { base8decode_printf "$@"; }
base16decode() { base16decode_xxd "$@"; }

capture__parse_log_to_json() {
	local target="$1"
	local valueopen=false module='' key='' value=''
	while read -r line; do
		if ${valueopen:-false}; then
			if [ -z "$line" ]; then
				case "$value" in
				('b8:'*)  echo "${value#*:}" | base8decode ;;
				('b16:'*) echo "${value#*:}" | base16decode ;;
				('b64:'*) echo "${value#*:}" | base64decode ;;
				(*)       echo >&2 "ERROR: unknown format (expected: b8|b16|b64)"; exit 1 ;;
				esac |
				jq -cMRs \
					--arg t "$target" \
					--arg m "$module" \
					--arg k "$key"    \
					'{ "target":($t), "module":($m), "key":($k), "value":(.) }'
				valueopen=false module='' key='' value=''
			else
				value="$value$line"		
			fi
		else
			case "$line" in
			('MODULE '*' KEY '*)
				module="${line#* }"
				module="${module%% *}"
				key="${line#* KEY }"
				valueopen=true
			;;
			('KEY '*)
				key="${line#KEY }"
				module="${key%%.*}"
				key="${key#*.}"
				valueopen=true
			;;
			(*) continue;;
			esac
		fi
	done
}
