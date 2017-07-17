# modules/example.bash
#
# Provides example handlers for an ircbot.bash module.
# This file is sourced by ircbot.bash when the module is loaded.
# Any handlers may be omitted in modules if they're not used.
# If an event matches multiple handlers, they're all called (e.g. on_readmsg is
# always called alongside on_privmsg).
#
# Global variables:
#
# IRCBOT_HOST: IRC server address
# IRCBOT_PORT: IRC server port
# IRCBOT_NICK: bot nick
# IRCBOT_LOGIN: bot login name
# IRCBOT_REALNAME: bot realname
# IRCBOT_MODULE: current module the bot is running


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi


# on_connect is called when the bot connects (or reconnects) to the server
on_connect() { # no args
}

# on_disconnect is called when the bot disconnects from the server
on_disconnect() { # no args
}

# on_readmsg is called whenever a message is read from the IRC server
on_readmsg() { # args: $1 - raw message, $2 - source, $3 - command, $4... - args
}

# on_sendmsg is called whenever sendmsg is used to send IRC messages
# If it returns non-zero, the sendmsg itself is aborted.
# Be careful not to create infinite sendmsg/on_sendmsg loops.
on_sendmsg() { # args: $1 - raw message, $2 - command, $3... - args
}

# on_privmsg is called whenever a PRIVMSG is received
on_privmsg() { # args: $1 - source, $2 - channel/target, $3 - message
}

# on_dm is called whenever a PRIVMSG direct (not channel) message is received
on_dm() { # args: $1 - source, $2 - message
}

# on_ctcp is called whenever a CTCP PRIVMSG direct (not channel) message is received
on_ctcp() { # args: $1 - source, $2 - CTCP command, $3 - CTCP argument
}

# on_self_join is called whenever the bot successfully joins a channel
on_self_join() { # args: $1 - channel
}

# on_self_kick is called whnever the bot is kicked from a channel
on_self_kick() { # args: $1 - source, $2 - channel, $3 - kick message
}

# on_self_part is called whenever the bot parts a channel
on_self_part() { # args: $1 - channel, $2 - part message
}

# on_self_invite is called whenever the bot is invited into a channel
on_self_invite() { # args: $1 - source, $2 - channel
}
