#include <stdlib.h>
#include <stdio.h>
#include <string.h>

struct source {
	char *nick;
	char *user;
	char *host;
};

struct message {
	char *_raw;
	struct source src;
	char *cmd;
	char **args;
	char *msg;
};

struct source parse_source(char *raw /* "nick!~user@host"; ~ is optional */) {
	struct source src;

	src.nick = src.user = src.host = NULL;

	src.nick = raw;
	while (*raw && *raw != '!') {
		++raw;
	}
	if (!*raw) {
		return src;
	}
	*raw = '\0';
	++raw;
	if (!*raw) {
		return src;
	}

	if (*raw == '~') {
		++raw;
		if (!*raw) {
			return src;
		}
	}

	src.user = raw;
	while (*raw && *raw != '@') {
		++raw;
	}
	if (!*raw) {
		return src;
	}
	*raw = '\0';
	src.host = raw + 1;

	return src;
}

struct message parse_message(char *raw /* ":source COMMAND arg1 arg2 arg3... :message"; no newlines at end, all but command optional */ ) {
	char *tmp;
	struct message msg;
	int argc;
	char **argv;
	int i;

	msg._raw = msg.src.nick = msg.src.user = msg.src.host = msg.cmd = msg.msg = NULL;
	msg.args = NULL;
	
	msg._raw = raw;

	for (i=0; i<2; ++i) {
		while (*raw && *raw != ' ') {
			*raw = '\0';
			++raw;
		}
		while (*raw && *raw == ' ') {
			*raw = '\0';
			++raw;
		}
	}

	if (*raw == ':') {
		tmp = raw + 1;
		if (!*tmp) {
			return msg;
		}
		while (*raw && *raw != ' ') {
			++raw;
		}
		while (*raw == ' ') {
			*raw = '\0';
			++raw;
		}
		msg.src = parse_source(tmp);
	}

	if (!*raw) {
		return msg;
	}
	msg.cmd = raw;

	while (*raw && *raw != ' ') {
		++raw;
	}
	while (*raw == ' ') {
		*raw = '\0';
		++raw;
	}

	tmp = raw;
	argc = 0;
	while (*raw && *raw != ':') {
		argc++;
		while (*raw && *raw != ' ') {
			++raw;
		}
		while (*raw == ' ') {
			++raw;
		}
	}
	raw = tmp;

	msg.args = malloc((argc + 1) * sizeof(char *));
	if (!msg.args) {
		return msg;
	}
	argv = msg.args;
	argv[argc] = NULL;
	while (*raw && *raw != ':') {
		*argv = raw;
		++argv;
		while (*raw && *raw != ' ') {
			++raw;
		}
		while (*raw == ' ') {
			*raw = '\0';
			++raw;
		}
	}

	if (*raw && *(raw+1)) {
		msg.msg = raw + 1;
	}

	return msg;
}

void free_message(struct message msg) {
	if (msg.args) {
		free(msg.args);
	}
	free(msg._raw);
}

int main(void) {
	char buf[1024];
	char bufcpy[1024];
	int len;
	struct message msg;

	while (fgets(buf, 1024, stdin)) {
		len = strlen(buf);
		if (!len) {
			continue;
		}
		if (buf[len-1] == '\n') {
			buf[len-1] = '\0';
			--len;
		}
		if (!len) {
			continue;
		}
		if (buf[len-1] == '\r') {
			buf[len-1] = '\0';
			--len;
		}
		strcpy(bufcpy, buf);
		msg = parse_message(buf);
		if (msg.cmd && !strcmp(msg.cmd, "PRIVMSG") && msg.args && *msg.args) {
			fflush(stdout);
			if (msg.src.nick) {
				printf("%s <%s> %s\n", *msg.args, msg.src.nick, msg.msg);
			} else {
				printf("%s <sed> %s\n", *msg.args, msg.msg);
			}
		}
		if (msg.args) {
			free(msg.args);
		}
	}

	return 0;
}
