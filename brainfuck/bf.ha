// Copyright (c) 2022 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use fmt;
use fs;
use io;
use os;
use os::exec;

// A valid operation for a Brainfuck program.
export type operation = enum {
	RIGHT, // Move the data pointer one cell to the right.
	LEFT,  // Move the data pointer one cell to the left.
	INCR,  // Increment the value at the data pointer.
	DECR,  // Decrement the value at the data pointer.
	IN,    // Read a byte from stdin into the cell at the data pointer.
	OUT,   // Write the byte at the data pointer to stdout.
	START, // Open a loop.
	END,   // Close a loop.
};

// A single point in a Brainfuck program.
export type point = struct {
	op: operation,
	// For loop brackets: the index of the matching bracket in the program.
	// void for all other operations.
	jump: (size | void),
};

// A Brainfuck program.
export type program = []point;

// Loads a Brainfuck program from the file at the provided path. The caller
// must free the return value.
export fn load(path: str) program = {
	const file = match (os::open(path)) {
	case let e: fs::error =>
		fmt::fatal(fs::strerror(e));
	case let f: io::file =>
		yield f;
	};
	defer match (io::close(file)) {
	case let e: io::error =>
		fmt::errorln("couldn't close {}: {}", path, io::strerror(e))!;
	case void => void;
	};

	const bytes = match (io::drain(file)) {
	case let e: io::error =>
		fmt::fatal(io::strerror(e));
	case let s: []u8 =>
		yield s;
	};
	defer free(bytes);

	let program: program = [];
	for (let i = 0z; i < len(bytes); i += 1) {
		append(program, point {
			op = switch (bytes[i]) {
			case '>' => yield operation::RIGHT;
			case '<' => yield operation::LEFT;
			case '+' => yield operation::INCR;
			case '-' => yield operation::DECR;
			case ',' => yield operation::IN;
			case '.' => yield operation::OUT;
			case '[' => yield operation::START;
			case ']' => yield operation::END;
			case =>
				// All other chars are comments
				// and should be ignored.
				continue;
			},
			jump = void, // TODO: loops
		});
	};

	return program;
};

// Runs a Brainfuck program. May exit on failure.
export fn run(program: program) void = {
	const memory_increment = 256z;
	// TODO: I do bounds-checking below, so somehow use [*]u8 instead.
	// But it doesn't seem to work easily with alloc().
	let memory: []u8 = alloc([0...], memory_increment);
	defer free(memory);

	let index = 0z;

	for (let i = 0z; i < len(program); i += 1) {
		switch (program[i].op) {
		case operation::RIGHT =>
			index += 1;
			if (index == len(memory)) {
				append(memory, [0...], memory_increment);
			};
		case operation::LEFT =>
			if (index == 0) {
				fmt::errorln("LEFT out of bounds")!;
				exec::kill(exec::self(),
					exec::signal::SIGSEGV)!;
			};
			index -= 1;
		case operation::INCR =>
			memory[index] += 1;
		case operation::DECR =>
			memory[index] -= 1;
		case operation::IN =>
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
		case operation::OUT =>
			io::write(os::stdout, [memory[index]])!;
		case operation::START =>
			abort("looping not implemented yet");
		case operation::END =>
			abort("looping not implemented yet");
		};
	};
};
