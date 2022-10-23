# [bf](https://sr.ht/~smlavine/bf)

A modular Brainfuck interpreter, written in Hare.

## Usage

As a standalone interpreter:

```
$ bf examples/wikipedia_hello.bf
Hello World!
$ printf 'a\n b\n  c\n' | bf examples/parrot.bf
a
 b
  c
$
```

As a Hare library:

```hare
// examples/main.ha
use bufio;
use io::{mode};
use os;
use strings;

use brainfuck;

export fn main() void = {
	const program = bufio::fixed(strings::toutf8(",[.,]"), mode::READ);
	const program = brainfuck::load(&program)!;
	defer free(program);

	const input = bufio::fixed(strings::toutf8("8675309\n"), mode::READ);
	brainfuck::run(program, &input, os::stdout)!;
};
```

```
$ hare run examples/main.ha
8675309
```

See `haredoc brainfuck` for full documentation.

## Installation

To build the binary:

```
make
```

To install the **library**:

```
make install
```

To install the **binary**:

```
make install-cmd
```

To uninstall the library or binary:

```
make uninstall
make uninstall-cmd
```

## Contributing

Patches may be sent to [~smlavine/bf-devel](https://lists.sr.ht/~smlavine/bf-devel).

## Copyright

Copyright (C) 2022 Sebastian LaVine

Licensed under the MPLv2. See [LICENSE][license].

[license]: https://git.sr.ht/~smlavine/bf/tree/master/item/LICENSE
