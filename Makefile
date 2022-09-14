.POSIX:
.SUFFIXES:

HARE = hare

NAME = bf

SRC = cmd/main.ha brainfuck/bf.ha

all: cmd

cmd: $(SRC)
	$(HARE) build $(HAREFLAGS) -o $(NAME) cmd

check:
	$(HARE) test

clean:
	rm -f $(NAME)

.PHONY: all check clean cmd
