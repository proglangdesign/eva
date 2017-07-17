# modules/channels.bash
#
# Provides persistant storage of channels the bot is in.
#
# Settings:
# CHANNELS_LIST: file to store channel list in


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi


channels_list=()


# joins channels in the list after connecting
on_connect() { # no args
	local ch
	channels_load
	for ch in "${channels_list[@]}"; do
		sendmsg JOIN "$ch"
	done
}

# adds a joined channel to the list
on_self_join() { # args: $1 - channel
	channels_add "$1"
}

# removes a channel from the list
on_self_kick() { # args: $1 - source, $2 - channel, $3 - kick message
	channels_remove "$2"
}

# removes a channel from the list
on_self_part() { # args: $1 - channel, $2 - part message
	channels_remove "$1"
}


channels_load() { # no args
	local line
	channels_list=()
	if [ -f "$CHANNELS_LIST" ]; then
		while IFS= read -r line || [ -n "$line" ]; do
			verbose 'loaded channel %s' "$line"
			channels_list+=("$line")
		done < "$CHANNELS_LIST"
	fi
}

channels_add() { # args: $1 - channel
	channels_load
	verbose 'adding channel %s' "$1"
	channels_list+=("$1")
	channels_dump
}

channels_remove() { # args: $1 - channel
	channels_load
	verbose 'removing channel %s' "$1"
	printf "%s\n" "${channels_list[@]}" | grep -xvF "$1" > "$CHANNELS_LIST" # XXX: ugly hack
	channels_load
}

channels_dump() {
	verbose 'dumping channel list: %s' "${channels_list[*]}"
	printf "%s\n" "${channels_list[@]}" | sort | uniq > "$CHANNELS_LIST"
}
