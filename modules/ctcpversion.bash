# modules/ctcpversion.bash
#
# Responds to CTCP VERSION direct message requests.
#
# Settings:
# CTCP_VERSION: response to the CTCP VERSION request; optional, defaults to bash version


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi


# respond to CTCP VERSION requests
on_ctcp() { # args: $1 - source, $2 - CTCP command, $3 - CTCP argument
	local version interpreter
	if [[ $2 == VERSION ]]; then
		if [[ -n ${CTCP_VERSION:-} ]]; then
			version="$CTCP_VERSION"
		else
			interpreter=sh # I should make it actually find out which interpreter it's running if it's not bash or zsh; also, fails on dash as it lacks --version
			if [ "$BASH_VERSION" ]; then
				interpreter=bash
			elif [ "$ZSH_VERSION" ]; then
				interpreter=zsh
			fi
			version="$("$interpreter" --version 2>&1 | sed 1q)"
		fi
		sendmsg NOTICE "$(parse_source_nick "$1")" "$(sed 's/^.*$/\x01&\x01/' <<< "VERSION $version")"
	fi
}
