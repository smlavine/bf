.POSIX:

HARE = hare

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

.PHONY: all check clean cmd
