# modules/sed.bash
#
# Provides sedbot.
#
# Settings:
# SED_TIMEOUT_BIN: path to the timeout script¹; optional to prevent regex DoS
# SED_TIMEOUT_MEM: maximum amount of memory (in kilobytes) a sed process may use
#
# ¹: https://github.com/pshved/timeout


if [ -z "$IRCBOT_MODULE" ]; then
	printf "error: %s is a module for ircbot.bash and should not be run separately\n" "$0"
	exit 1
fi

declare -g -A sed_messages

# seds a previous message if instucted to
on_privmsg() { # args: $1 - source, $2 - channel/target, $3 - message
	local where nick msg
	local targetednick origmsg origkey
	local key target fromnick regexed ctcp

	where="$2"
	nick="$(parse_source_nick "$1")"
	msg="$3"
	if [[ $where == "$IRCBOT_NICK" ]]; then
		where="$nick"
	fi

	# targeted means the message was ``<user1> user2: s/foo/bar/'' (targets user2's last message)
	origmsg="$msg"
	origkey="$where $nick"
	if targetednick="$(parse_targeted_nick "$msg")"; then
		nick="$targetednick"
		msg="$(parse_targeted_msg "$msg")"
	fi


	key="$where $nick"
	target="${sed_messages[$key]:-}"

	# handle regexing CTCP ACTIONs properly
	ctcp="$(parse_ctcp_command "$target")" || true
	if [[ $ctcp == ACTION ]]; then
		target="$(parse_ctcp_message "$target")"
		fromnick="$(printf "\\x02* %s\\x02" "$nick")"
	else
		fromnick="<$nick>"
	fi

	if regexed="$(sed_replace "$msg" "$target")"; then # if a replacement was done, send it
		sendmsg PRIVMSG "$where" "$fromnick $regexed"
	else # otherwise, store the triggering message
		sed_messages[$origkey]="$origmsg"
	fi
}

sed_replace() { # args: $1 - sed s expression, $2 - text to regex
	local msg target
	local l pos i p del
	local regexps ok t target

	msg="$1"
	target="$2"

	del="${msg:1:1}"
	if [[ -z $del ]] || [[ $(indexof '/|,!:' "$del") -lt 0 ]]; then
		return 1
	fi

	# TODO: rewrite so that only one expression is tokenized at once (allows different delimiters)

	# tokenize
	l=()
	pos="$(indexof "$msg" "$del")"
	while ((pos >= 0)); do
		i=0
		((p=pos-i-1))
		while ((p >= 0)) && [[ ${msg:$p:1} == '\' ]]; do # count \ characters
			((i++))
			((p=pos-i-1))
		done
		if ((i%2 == 0)); then
			l+=("${msg:0:$pos}")
			((p=pos+1))
			msg="${msg:$p}"
			pos=0
		else
			((pos++))
		fi
		p="$(indexof "${msg:$pos}" "$del")"
		if ((p >= 0)); then
			((pos+=p))
		else
			pos=$p
		fi
	done
	l+=("$msg")

	# l is now an array of the expr separated by unescaped delimiters

	i=0
	regexps=()
	ok=1

	# s/expr1/repl1/opts1 s/expr2/repl2/opts2 s/expr3/repl3
	while ((i < ${#l[@]})); do
		# begins with s
		if [ "${l[$i]}" != "s" ]; then
			break
		fi
		((i++))

		# expr
		if ((i >= ${#l[@]})); then
			break
		fi
		exp="${l[$i]}"
		((i++))

		# repl
		if ((i >= ${#l[@]})); then
			break
		fi
		repl="${l[$i]}"
		((i++))

		# opts
		opts=''
		if ((i < ${#l[@]})); then
			opts="${l[$i]}"
			p=0
			while ((p < ${#opts})); do
				c="${opts:$p:1}"
				if ! [[ $c =~ ^[ig0-9]$ ]]; then # allowed opts are 0-9, i and g
					ok=0
					break
				fi
				((p++))
			done
			if ! ((ok)); then
				# multiple regexps per line
				if [[ "${opts:$p:1}" == ' ' || "${opts:$p:1}" == ';' ]]; then # expression separators are space and ;
					p1=$p
					while ((p < ${#opts})); do
						if [[ "${opts:$p:1}" != ' ' && "${opts:$p:1}" != ';' ]]; then
							break
						fi
						p=$((p+1))
					done
					l[$i]="${opts:$p}"
					opts="${opts:0:$p1}"
					ok=1
				else
					break
				fi
			fi
		fi

		if ((ok)); then
			regexps+=("s$del$exp$del$repl$del$opts")
		fi
	done


	if ! ((ok)) || ((${#regexps[@]} == 0)); then
		return 1
	fi

	t="$target"
	for re in "${regexps[@]}"; do
		if [[ -n ${SED_TIMEOUT_BIN:-} ]]; then
			target="$("$SED_TIMEOUT_BIN" -m "$SED_TIMEOUT_MEM" sed -e "$re" <<< "$target")"
		else
			target="$(sed -e "$re" <<< "$target")"
		fi
	done
	target="$(trimrn <<< "$target")"
	verbose "sed '%s' <<< '%s' >>> '%s'" "$1" "$2" "$target"
	if [[ $target != "$t" ]]; then
		if [[ -n $target ]]; then
			trimrn <<< "$target"
			return 0
		fi
	fi
	return 1
}
