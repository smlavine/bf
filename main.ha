use fmt;
use os;

use brainfuck;

export fn main() void = {
	if (len(os::args) != 2) {
		fmt::fatalf("usage: {} <programfile>", os::args[0]);
	};
	const program = brainfuck::load(os::args[1]);
	defer free(program);
	brainfuck::run(program);
};
