# modules/ibip.bash
#
# Responds to ``.bots''
#
# Settings:
# IBIP_TIMEOUT: seconds that must pass between IBIP responses; optional
# IBIP_COMMENT: the comment at the end of the IBIP message; optional
# IBIP_NOTICE: set to 1 to respond with NOTICE instead of PRIVMSG; optional


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi


ibip_last=0

if [[ -z ${IBIP_COMMENT:-} ]]; then
	IBIP_COMMENT='See https://git.clsr.net/mbibot'
fi

# on_privmsg is called whenever a PRIVMSG is received
on_privmsg() { # args: $1 - source, $2 - channel/target, $3 - message
	local ts where msgtype
	where="$2"
	if [[ $where == "$IRCBOT_NICK" ]]; then
		where="$(parse_source_nick "$1")"
	fi
	msgtype=PRIVMSG
	if [[ ${IBIP_NOTICE:-0} -ne 0 ]]; then
		msgtype=NOTICE
	fi
	if [[ $3 == ".bots" ]]; then
		ts="$(printf '%(%s)T' -1)"
		if [[ -z ${IBIP_TIMEOUT:-} ]] || ((ts - ibip_last > IBIP_TIMEOUT)); then
			ibip_last="$ts"
			sendmsg "$msgtype" "$where" "Reporting in! [bash] $IBIP_COMMENT"
		fi
	fi
}
