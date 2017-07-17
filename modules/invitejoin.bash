# modules/invitejoin.bash
#
# Joins channels when invited.


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi


# joins the channel the bot was invited to
on_self_invite() { # args: $1 - source, $2 - channel
	sendmsg JOIN "$2"
}
