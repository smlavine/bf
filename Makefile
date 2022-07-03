.POSIX:
.SUFFIXES:

HARE = hare

NAME = bf

SRC = main.ha brainfuck/bf.ha

all: $(NAME)

$(NAME): $(SRC)
	$(HARE) build $(HAREFLAGS) -o $@

check:
	$(HARE) test

clean:
	rm -f $(NAME)

.PHONY: all check clean
