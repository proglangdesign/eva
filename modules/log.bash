# modules/log.bash
#
# Logs IRC messages and bot debug/error output.
#
# Settings:
# LOG_IRC: log file for IRC protocol traffic
# LOG_ERR: log file for stderr messages
# LOG_SHOW_IRC: set to non-zero to show IRC output on stdout


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi


if [[ -n ${LOG_IRC:-} ]]; then
	if [[ ${LOG_SHOW_IRC:-0} -ne 0 ]]; then
		exec 14> >(tee -a -- "$LOG_IRC")
	else
		exec 14>>"$LOG_IRC"
	fi
elif [[ ${LOG_SHOW_IRC:-0} -ne 0 ]]; then
	exec 14>&1
fi

if [[ -n ${LOG_ERR:-} ]]; then
	exec 2> >(tee -a -- "$LOG_ERR" >&2)
fi


# log received messages
on_readmsg() { # args: $1 - raw message, $2 - source, $3 - command, $4... - args
	printf "%s <<< %s\n" "$(log_timestamp)" "$1" >&14
}

# log sent messages
on_sendmsg() { # args: $1 - raw message, $2 - command, $3... - args
	printf "%s >>> %s\n" "$(log_timestamp)" "$1" >&14
}

log_timestamp() {
	TZ=UTC date -u +%s.%N
}
