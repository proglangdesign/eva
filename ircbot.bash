#!/bin/bash


IRCBOT_VERSION=0.1.0


# Modular IRC bot framework in bash
#
# Modules should be ./modules/*.bash
#
# Run as `bash ircbot.bash path/to/config.bash`


# Exposed variables:
#
# IRCBOT_MODULE
#     the name of the current module
#
# IRCBOT_VERSION
#     the version of the bot
#
# See config.bash for other exposed variables


# Exposed functions:
#
# verbose $format $args...
#     log a message prefixed with the current module name to stderr (and error
#     log if using modules/log); same arguments as printf
#
# parse_source_nick $source
#     prints nick from source; returns 1 when no nick
#
# parse_source_user $source
#     prints username from source; returns 1 when no username
#
# parse_source_host $source
#     prints hostname from source; returns 1 when no hostname
#
# parse_targeted_nick $msg
#     prints targeted nick (message prefixed with "nick: " or "nick, ") from a PRIVMSG message
#
# parse_targeted_msg $msg
#     prints message part of a targeted message (all but the "nick: " or "nick, " prefix) from a PRIVMSG message
#
# parse_ctcp_command $msg
#     prints the CTCP command from a PRIVMSG message; returns 1 if not valid CTCP message
#
# parse_ctcp_message $msg
#     prints the CTCP message from a PRIVMSG message; returns 1 if not valid CTCP message
#
# trimrn
#     removes all linebreaks and carriage returns from stdin
#
# indexof $haystack $needle
#     prints the index of $needle in $haystack or -1 if not found
#
# sendmsg $command $args...
#     sends an IRC command; only the last argument may contain spaces
# 


set -euo pipefail

IRCBOT_MODULE=ircbot

_events=(connect disconnect readmsg sendmsg privmsg dm ctcp self_join self_kick self_part self_invite)

verbose() {
	if [ -n "$IRCBOT_VERBOSE" ] && [ "$IRCBOT_VERBOSE" -ne 0 ]; then
		printf "[%s] $1\n" "$IRCBOT_MODULE" "${@:2}" >&2
	fi
}

connect() {
	if ! exec 3<>"/dev/tcp/$IRCBOT_HOST/$IRCBOT_PORT"; then
		return $?
	fi

	if ! sendmsg NICK "$IRCBOT_NICK"; then
		return $?
	fi
	if ! sendmsg USER "$IRCBOT_LOGIN 8 *" "$IRCBOT_REALNAME"; then
		return $?
	fi

	return 0
}


#nick!login@host
# 1-nick, 2-login, 3-host
_source_regex='^\([^!]\+\)!\([^@]\+\)@\(.*\)$'

parse_source_nick() { # args: $1 - source
	sed "s/$_source_regex/\\1/" <<< "$1"
}

parse_source_login() { # args: $1 - source
	sed "s/$_source_regex/\\2/" <<< "$1"
}

parse_source_host() { # args: $1 - source
	sed "s/$_source_regex/\\3/" <<< "$1"
}


_ctcp_regex='^\x01\([A-Za-z]\+\) \?\([^\x01]*\)\x01$'

parse_ctcp_command() { # args: $1 - PRIVMSG message
	local ctcp
	ctcp="$(sed "s/$_ctcp_regex/\\U\\1/" <<< "$1")"
	if [[ $ctcp != "$1" ]]; then
		printf "%s\n" "$ctcp"
		return 0
	fi
	return 1
}

parse_ctcp_message() { # args: $1 - PRIVMSG message
	local msg
	msg="$(sed "s/$_ctcp_regex/\\2/" <<< "$1")"
	if [[ $msg != "$1" ]]; then
		printf "%s\n" "$ctcp"
		return 0
	fi
	return 1
}


_targeted_regex='^\([^ /|,!:]\+\)[:,] \(.\+\)'

parse_targeted_nick() { # args: $1 - PRIVMSG message
	local target
	target="$(sed "s/$_targeted_regex/\\1/" <<< "$1")"
	if [[ -n $target && $target != "$1" ]]; then
		sed : <<< "$target"
		return 0
	fi
	return 1
}

parse_targeted_msg() { # args: $1 - PRIVMSG message
	local target
	target="$(sed "s/$_targeted_regex/\\2/" <<< "$1")"
	if [[ -n $target && $target != "$1" ]]; then
		sed : <<< "$target"
		return 0
	fi
	return 1
}


trimrn() { # no args, put input to stdin
	#sed -e 's/\r//g' -e 's/\n//g' -e 1q
	tr -d '\r\n'
}

indexof() { # args: $1 - haystack, $2 - needle
	local str search i
	str="$1"
	search="$2"

	i=0;
	while :; do
		if ((i >= ${#str})); then
			i=-1
			break
		fi
		if [[ ${str:$i:1} == "$search" ]]; then
			break
		fi
		((i++))
	done

	echo "$i"
}


sendmsg() { # args: $1 - command, $2... - args (any number)
	local msg oldifs cmd args
	msg="$(sed 's/.*/\U&/' <<< "$1")"
	cmd="$msg"
	shift
	args=("$@")
	if [[ $# -gt 1 ]]; then
		oldifs="$IFS"
		IFS=' '
		msg="$msg ${*:1:(($#-1))}"
		IFS="$oldifs"
		shift $(($#-1))
	fi
	if [[ $# -gt 0 ]]; then
		msg="$msg :$1"
	fi
	msg="$(trimrn <<< "$msg" | sed 's/^\(.\{,'"$IRCBOT_MAX_LINE_LENGTH"'\}\).*/\1/')"
	if ! _trigger sendmsg "$msg" "$cmd" "${args[@]}"; then
		return $?
	fi
	printf "%s\r\n" "$msg" >&3
	return $?
}

_readmsg() {
	local line
	IFS= read -r -u 3 -t "${IRCBOT_READ_TIMEOUT:-300}" line
	success=$?
	printf "%s\n" "$line" | trimrn
	return $success
}


_readloop() {
	local orig msg src cmd args pos

	while :; do
		if ! msg="$(_readmsg)"; then
			verbose 'disconnected from server'
			return 1
		fi

		orig="$msg"

		# has source?
		src=
		if [[ ${msg:0:1} == : ]]; then
			pos="$(indexof "$msg" ' ')"
			if [[ $pos -lt 0 ]]; then
				return 1
			fi
			src="${msg:1:$pos}"
			((++pos))
			msg="${msg:$pos}"
		fi

		# grab the command
		pos="$(indexof "$msg" ' ')"
		if [[ $pos -lt 0 ]]; then
			cmd="$msg"
			msg=
		else
			cmd="${msg:0:$pos}"
			((++pos))
			msg="${msg:$pos}"
		fi

		# parse args, ending when no more spaces or on last arg starting with :
		args=()
		while :; do
			if [[ ${msg:0:1} = : ]]; then
				args+=("${msg:1}")
				break
			fi
			pos="$(indexof "$msg" ' ')"
			if [[ $pos -lt 0 ]]; then
				args+=("$msg")
				break
			fi
			args+=("${msg:0:$pos}")
			((++pos))
			msg="${msg:$pos}"
		done

		#printf "raw: '%s'\n" "$orig"
		#printf "source: '%s'\n" "$src"
		#printf "nick: '%s'\n" "$(parse_source_nick "$src")"
		#printf "command: '%s'\n" "$cmd"
		#printf "args:\n"
		#printf "  %s\n" "${args[@]}"
		#echo


		_handle_msg "$orig" "$src" "$cmd" "${args[@]}"
	done
}

_handle_msg() { # args: $1 - raw message, $2 - source, $3 - command, $4... - args
	local orig src cmd args nick where who why msg ctcp
	orig="$1"
	src="$2"
	cmd="$3"
	args=("${@:4}")


	_trigger readmsg "$orig" "$src" "$cmd" "${args[@]}"


	# XXX sometimes, you have to respond to a PING before registering
	if [[ $_pre_register != 0 && $cmd != NOTICE && $cmd != PING ]]; then
		_pre_register=0
		_trigger connect
	fi



	case "$cmd" in
		JOIN)
			nick="$(parse_source_nick "$src")"
			where="${args[0]:-}"
			if [[ $nick == "$IRCBOT_NICK" ]]; then
				_trigger self_join "$where"
			fi
			;;

		KICK)
			nick="$(parse_source_nick "$src")"
			who="${args[0]}"
			where="${args[1]}"
			why="${args[2]:-}"
			if [[ $who == "$IRCBOT_NICK" ]]; then
				_trigger self_kick "$src" "$where" "$why"
			fi
			;;

		PART)
			nick="$(parse_source_nick "$src")"
			where="${args[0]}"
			why="${args[1]:-}"
			if [[ $nick == "$IRCBOT_NICK" ]]; then
				_trigger self_part "$where" "$why"
			fi
			;;

		INVITE)
			nick="$(parse_source_nick "$src")"
			who="${args[0]}"
			where="${args[1]}"
			if [[ $who == "$IRCBOT_NICK" ]]; then
				_trigger self_invite "$src" "$where"
			fi
			;;

		433)
			verbose 'nick %s is already taken' "$IRCBOT_NICK"
			#exit 1
			return # as if disconnected
			;;

		PRIVMSG)
			where="${args[0]}"
			msg="${args[1]}"

			_trigger privmsg "$src" "$where" "$msg"

			if [[ $where == "$IRCBOT_NICK" ]]; then
				_trigger dm "$src" "$msg"

				if ctcp="$(parse_ctcp_command "$msg")"; then
					_trigger ctcp "$src" "$ctcp" "$(parse_ctcp_message "$msg")"
				fi
			fi
			;;
	esac

}

_trigger() { # args: $1 - event, $2... - event args
	local mod ev fn ret
	ev="$1"
	shift
	ret=0
	for mod in "${IRCBOT_MODULES[@]}"; do
		fn="_module_${mod}_on_${ev}"
		if declare -F "$fn" >/dev/null; then
			IRCBOT_MODULE="$mod"
			if ! "$fn" "$@"; then
				ret=$?
			fi
			IRCBOT_MODULE=ircbot
		fi
	done
	return "$ret"
}

_load_modules() {
	local mod ev
	for mod in "${IRCBOT_MODULES[@]}"; do
		IRCBOT_MODULE="$mod"
		source "modules/$mod.bash"
		IRCBOT_MODULE=ircbot
		verbose "sourced module %s" "$mod"
		for ev in "${_events[@]}"; do
			if declare -F "on_${ev}" >/dev/null; then
				# this is kinda evil
				eval "$(echo "_module_${mod}_on_${ev}()"; declare -f "on_${ev}" | tail -n +2)"
				unset -f "on_${ev}"
				verbose "module %s installed handler %s" "$mod" "$ev"
			fi
		done
	done
}

_main() { # args: $1 - config file
	source "$1"
	_load_modules
	while :; do
		if connect; then
			#_trigger connect
			verbose 'connected'
			sleep "${IRCBOT_SLEEP_CONNECT:-0}"
			_pre_register=1
			_readloop
		fi
		_trigger disconnect
		verbose 'reconnecting in %d seconds...' "${IRCBOT_SLEEP_RECONNECT:-10}"
		sleep "${IRCBOT_SLEEP_RECONNECT:-10}"
	done
}

_main "$@"
