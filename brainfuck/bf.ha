// Copyright (c) 2022 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use io;

// The version of the library.
export def VERSION: str = "1.0.0";

// A valid operation for a Brainfuck program.
export type operation = enum {
	LEFT,  // Move the data pointer one cell to the left.
	RIGHT, // Move the data pointer one cell to the right.
	DECR,  // Decrement the value at the data pointer.
	INCR,  // Increment the value at the data pointer.
	IN,    // Read a byte from stdin into the cell at the data pointer.
	OUT,   // Write the byte at the data pointer to stdout.
	OPEN,  // Open a loop.
	CLOSE, // Close a loop.
};

// A single point in a Brainfuck program.
export type point = struct {
	op: operation,
	// For loop brackets: the index of the matching bracket in the program.
	// It has no meaning for any other operations.
	jump: size,
};

// A Brainfuck program.
export type program = []point;

// An error that occurs when an opening bracket is present without a
// corresponding closing bracket.
export type unexpected_open = !void;

// An error that occurs when an closing bracket is present without a
// corresponding opening bracket.
export type unexpected_close = !void;

// An error that can occur in the course of loading a Brainfuck program. See
// [[load]].
export type load_error = !(unexpected_open | unexpected_close | io::error);

// An error that occurs when a negative memory access attempt is made.
export type nmaa = !void;

// An error that can occur in the course of running a Brainfuck program. See
// [[run]].
export type run_error = !(nmaa | io::error);

// An error that can occur in the course of loading or running a Brainfuck
// program.
export type error = !(...load_error | ...run_error);

// Loads a Brainfuck program from the provided handle. The caller
// must free the return value on success. Returns [[load_error]] on failure.
export fn load(h: io::handle) (program | error) = {
	const bytes = io::drain(h)?;
	defer free(bytes);

	// Stack that holds indices of opening loop brackets in the program.
	// When an opening backet is found, its index is added to the top of
	// the stack. When a closing bracket is found, the top index is taken
	// off the stack and used as the jump point for that closing bracket.
	// The already-parsed opening bracket point is modified to use the
	// index of the closing bracket as its jump point.
	let loopstack: []size = [];
	defer free(loopstack);

	let program: program = [];
	for (let i = 0z; i < len(bytes); i += 1) {
		const point = switch (bytes[i]) {
		case '[' =>
			append(loopstack, len(program));
			yield point {
				op = operation::OPEN,
				// jump is set to the correct index when the
				// ']' is found.
				jump = 0,
			};
		case ']' =>
			if (len(loopstack) == 0) {
				// No corresponding opening bracket
				free(program);
				return unexpected_close;
			};

			// Set open bracket to jump to this bracket
			const open_bracket = loopstack[len(loopstack) - 1];
			delete(loopstack[len(loopstack) - 1]);
			program[open_bracket].jump = len(program);

			yield point {
				op = operation::CLOSE,
				jump = open_bracket,
			};
		case =>
			yield point {
				op = switch (bytes[i]) {
				case '<' => yield operation::LEFT;
				case '>' => yield operation::RIGHT;
				case '-' => yield operation::DECR;
				case '+' => yield operation::INCR;
				case ',' => yield operation::IN;
				case '.' => yield operation::OUT;
				case =>
					// All other characters are comments.
					continue;
				},
				jump = 0,
			};
		};

		append(program, point);
	};

	if (len(loopstack) != 0) {
		free(program);
		return unexpected_open;
	};

	return program;
};

// Runs a Brainfuck [[program]].
// Returns void on success, [[run_error]] on failure.
export fn run(
	program: program,
	in: io::handle,
	out: io::handle,
) (void | error) = {
	const memory_increment = 256z;

	// Because we do our own bounds checking below, we don't need to use
	// Hare's built-in slice bounds checking. This provides a slight
	// performance improvement.
	// [0]: https://harelang.org/tutorials/introduction/#arrays-and-slices-continued
	let _mem: []u8 = alloc([0...], memory_increment);
	let memory: *[*]u8 = _mem: *[*]u8;
	defer free(_mem);

	let index = 0z;

	for (let p = 0z; p < len(program); p += 1) {
		switch (program[p].op) {
		case operation::LEFT =>
			if (index == 0) {
				return nmaa;
			};
			index -= 1;
		case operation::RIGHT =>
			index += 1;
			if (index == len(_mem)) {
				append(_mem, [0...], memory_increment);
				memory = _mem: *[*]u8;
			};
		case operation::DECR =>
			memory[index] -= 1;
		case operation::INCR =>
			memory[index] += 1;
		case operation::IN =>
			match (io::read(in, memory[index..index + 1])?) {
			case io::EOF =>
				// There is no consensus among implementations
				// as to behavior on EOF[0]. One of the easiest
				// and most common solutions is to set the cell
				// to 0.
				// [0]: https://en.wikipedia.org/Brainfuck#End-of-file_behavior
				memory[index] = 0;
			case let s: size =>
				assert(s == 1, "bad io::read");
			};
		case operation::OUT =>
			io::write(out, [memory[index]])?;
		case operation::OPEN =>
			if (memory[index] == 0) {
				p = program[p].jump;
			};
		case operation::CLOSE =>
			if (memory[index] != 0) {
				p = program[p].jump;
			};
		};
	};
};

// Converts a Brainfuck error into a user-friendly string.
export fn strerror(e: error) str = {
	match (e) {
	case let ioe: io::error =>
		return io::strerror(ioe);
	case nmaa =>
		return "Attempted to access negative memory";
	case unexpected_open =>
		return "Unexpected '[': No corresponding closing bracket";
	case unexpected_close =>
		return "Unexpected ']': No corresponding opening bracket";
	};
};
