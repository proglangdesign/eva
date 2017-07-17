########################################
# core settings

# set to non-zero to enable verbose output to stderr
IRCBOT_VERBOSE=1

# IRC server address
IRCBOT_HOST=chat.freenode.net

# IRC server port
IRCBOT_PORT=6667

# bot nick
IRCBOT_NICK=eva

# bot login name
IRCBOT_LOGIN=$IRCBOT_NICK

# bot realname
IRCBOT_REALNAME=$IRCBOT_NICK

# list of modules to load (array, note the parentheses)
IRCBOT_MODULES=(ping ctcpversion ibip channels log sed)

# truncate lines to this many bytes
IRCBOT_MAX_LINE_LENGTH=400

# sleep after making connection to the IRC server
IRCBOT_SLEEP_CONNECT=0

# sleep before reconnecting on disconnect
IRCBOT_SLEEP_RECONNECT=10

# seconds before reconnect if no line is read (set to more than server ping interval)
IRCBOT_READ_TIMEOUT=300


########################################
# modules/channels

# path to the list of stored channels
CHANNELS_LIST=./ircbot.channels


########################################
# modules/ctcpversion

# custom response to CTCP VERSION requests instead of bash version; optional
CTCP_VERSION="$(sed --version 2>&1 | trimrn)" # some seds don't have --version, have to fix?


########################################
# modules/ibip

# seconds between IBIP responses; optional
IBIP_TIMEOUT=5

# custom comment on IBIP response; optional
IBIP_COMMENT="See https://github.com/clsr/sedbot and pretend it's better"

# set to non-zero to respond to IBIP using NOTICE instead of PRIVMSG; optional
IBIP_NOTICE=0


########################################
# modules/log

# log file for IRC protocol traffic; optional
LOG_IRC=./ircbot.log

# log file for stderr messages; optional
LOG_ERR=./ircbot.err

# set to non-zero to show IRC output on stdout; optional
LOG_SHOW_IRC=1


########################################
# modules/sed

# path to the timeout script; optional, used to prevent DoS regexps
# see https://github.com/pshved/timeout
SED_TIMEOUT_BIN=./timeout

# amount of memory in kilobytes that a sed process may use when using the timeout script
SED_TIMEOUT_MEM=16386
