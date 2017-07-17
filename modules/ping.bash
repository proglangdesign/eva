# modules/ping.bash
#
# Responds to IRC PINGs.


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi


# respond to PINGs
on_readmsg() { # args: $1 - raw message, $2 - source, $3 - command, $4... - args
	if [[ $3 == PING ]]; then
		sendmsg PONG "${@:4}"
	fi
}
