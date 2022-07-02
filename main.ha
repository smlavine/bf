use bufio;
use fmt;
use fs;
use io;
use os;
use os::exec;

// The return value must be freed.
fn read_program(path: str) []u8 = {
	const file = match (os::open(path)) {
	case let e: fs::error =>
		fmt::fatal(fs::strerror(e));
	case let f: io::file =>
		yield f;
	};

	const bytes = match (io::drain(file)) {
	case let e: io::error =>
		fmt::fatal(io::strerror(e));
	case let s: []u8 =>
		yield s;
	};

	match (io::close(file)) {
	case let e: io::error =>
		fmt::errorln("couldn't close {}: {}", path, io::strerror(e))!;
	case void => void;
	};

	return bytes;
};

fn run(program: []u8) void = {
	const memory_increment = 256z;
	// TODO: I do bounds-checking below, so somehow use [*]u8 instead.
	// But it doesn't seem to work easily with alloc().
	let memory: []u8 = alloc([0...], memory_increment);
	defer free(memory);

	let index = 0z;

	for (let i = 0z; i < len(program); i += 1) {
		switch (program[i]) {
		case '>' =>
			index += 1;
			if (index == len(memory)) {
				append(memory, [0...], memory_increment);
			};
		case '<' =>
			if (index == 0) {
				exec::kill(exec::self(),
					exec::signal::SIGSEGV)!;
			};
			index -= 1;
		case '+' =>
			memory[index] += 1;
		case '-' =>
			memory[index] -= 1;
		case '.' =>
			io::write(os::stdout, [memory[index]])!;
		case ',' =>
			match (io::read(os::stdin, memory[index..index + 1])) {
			case let e: io::error =>
				fmt::fatal(io::strerror(e));
			case io::EOF =>
				// According to the Wikipedia article for
				// Brainfuck, there are three common ways to
				// handle EOF: set to 0, set to -1, or no
				// change. I choose to set to zero, because it
				// is the easiest to implement (no signed
				// numbers), and easy to detect by the
				// programmer.
				void;
			case let s: size =>
				assert(s == 1, "bad io::read");
			};
		case '[' =>
			abort("looping not implemented yet");
		case ']' =>
			abort("looping not implemented yet");
		case =>
			// All other characters are comments and should be
			// ignored.
			void;
		};
	};
};

export fn main() void = {
	if (len(os::args) != 2) {
		fmt::fatalf("usage: {} <programfile>", os::args[0]);
	};
	const program = read_program(os::args[1]);
	defer free(program);
	run(program);
};
