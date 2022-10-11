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
