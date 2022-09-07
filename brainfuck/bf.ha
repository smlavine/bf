// Copyright (c) 2022 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use fmt;
use io;

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
	// void for all other operations.
	jump: (void | size),
};

// A Brainfuck program.
export type program = []point;

// An error that occurs when an opening bracket is present without a
// corresponding closing bracket.
export type unexpected_open = !void;

// An error that occurs when an closing bracket is present without a
// corresponding opening bracket.
export type unexpected_close = !void;

// An error that occurs in the course of loading a Brainfuck program. See
// [[load]].
export type load_error = !(unexpected_open | unexpected_close | io::error);

// Negative memory access attempt.
export type nmaa = !void;

// An error that occurs in the course of running a Brainfuck program. See
// [[run]].
export type run_error = !(nmaa | io::error);

// Loads a Brainfuck program from the file at the provided path. The caller
// must free the return value on success. Returns [[load_error]] on failure.
export fn load(file: io::file) (program | load_error) = {
	const bytes = io::drain(file)?;
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
		case '<' =>
			yield point { op = operation::LEFT, jump = void };
		case '>' =>
			yield point { op = operation::RIGHT, jump = void };
		case '-' =>
			yield point { op = operation::DECR, jump = void };
		case '+' =>
			yield point { op = operation::INCR, jump = void };
		case ',' =>
			yield point { op = operation::IN, jump = void };
		case '.' =>
			yield point { op = operation::OUT, jump = void };
		case '[' =>
			append(loopstack, len(program)); // index after append

			// The jump point for opening loop brackets is
			// initialized to void, but will be set to the index
			// of the corresponding closing loop bracket once it
			// is read.
			yield point { op = operation::OPEN, jump = void };
		case ']' =>
			if (len(loopstack) == 0) {
				free(program);
				return unexpected_close;
			};
			const open = loopstack[len(loopstack) - 1];
			delete(loopstack[len(loopstack) - 1]);
			program[open].jump = len(program); // index after append
			yield point { op = operation::CLOSE, jump = open };
		case =>
			continue; // All other characters are comments.
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
) (void | run_error) = {
	const memory_increment = 256z;
	// TODO: I do bounds-checking below, so somehow use [*]u8 instead.
	// But it doesn't seem to work easily with alloc().
	let memory: []u8 = alloc([0...], memory_increment);
	defer free(memory);

	let index = 0z;

	for (let i = 0z; i < len(program); i += 1) {
		switch (program[i].op) {
		case operation::LEFT =>
			if (index == 0) {
				return nmaa;
			};
			index -= 1;
		case operation::RIGHT =>
			index += 1;
			if (index == len(memory)) {
				append(memory, [0...], memory_increment);
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
				i = program[i].jump as size;
			};
		case operation::CLOSE =>
			if (memory[index] != 0) {
				i = program[i].jump as size;
			};
		};
	};
};

// Converts a Brainfuck error into a user-friendly string.
export fn strerror(e: (...load_error | ...run_error)) str = {
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
