# Copyright (c) 2022 Sebastian LaVine <mail@smlavine.com>
# SPDX-License-Identifier: CC0-1.0

.POSIX:

include config.mk

NAME = bf

LIBSRC = brainfuck/bf.ha
CMDSRC = cmd/main.ha
SRC = $(LIBSRC) $(CMDSRC)

all: cmd

$(NAME): cmd

cmd: $(SRC)
	$(HARE) build $(HAREFLAGS) -o $(NAME) cmd

check:
	$(HARE) test

clean:
	rm -f $(NAME)

install:
	mkdir -p $(DESTDIR)$(THIRDPARTYDIR)/brainfuck
	cp $(LIBSRC) $(DESTDIR)$(THIRDPARTYDIR)/brainfuck

uninstall:
	rm -rf $(DESTDIR)$(THIRDPARTYDIR)/brainfuck

install-cmd: $(NAME)
	cp $(NAME) $(DESTDIR)$(PREFIX)/bin

uninstall-cmd:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(NAME)

.PHONY: all check clean cmd install install-cmd uninstall uninstall-cmd
