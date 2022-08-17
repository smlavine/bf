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
	START, // Open a loop.
	END,   // Close a loop.
};

// Unexpected character encountered in the course of running a program.
// Currently used only for loop brackets encountered without a matching
// opening/closing bracket.
export type unexpected = !operation;

// A single point in a Brainfuck program.
export type point = struct {
	op: operation,
	// For loop brackets: the index of the matching bracket in the program.
	// void for all other operations.
	jump: (size | void),
};

// A Brainfuck program.
export type program = []point;

// Negative memory access attempt.
export type nmaa = !void;

// An error that occurs in the course of running a Brainfuck program.
// Currently only used in the event of an negative memory access attempt;
// see [[run]].
export type error = !(nmaa | unexpected);

// Loads a Brainfuck program from the file at the provided path. The caller
// must free the return value.
export fn load(file: io::file) program = {
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
			case '<' => yield operation::LEFT;
			case '>' => yield operation::RIGHT;
			case '-' => yield operation::DECR;
			case '+' => yield operation::INCR;
			case ',' => yield operation::IN;
			case '.' => yield operation::OUT;
			case '[' => yield operation::START;
			case ']' => yield operation::END;
			case =>
				// All other characters are comments.
				continue;
			},
			jump = void, // TODO: loops
		});
	};

	return program;
};

// Runs a Brainfuck program. Returns void on success, error on failure.
export fn run(p: program, in: io::handle, out: io::handle) (void | error) = {
	const memory_increment = 256z;
	// TODO: I do bounds-checking below, so somehow use [*]u8 instead.
	// But it doesn't seem to work easily with alloc().
	let memory: []u8 = alloc([0...], memory_increment);
	defer free(memory);

	let index = 0z;

	for (let i = 0z; i < len(p); i += 1) {
		switch (p[i].op) {
		case operation::RIGHT =>
			index += 1;
			if (index == len(memory)) {
				append(memory, [0...], memory_increment);
			};
		case operation::LEFT =>
			if (index == 0) {
				return nmaa;
			};
			index -= 1;
		case operation::INCR =>
			memory[index] += 1;
		case operation::DECR =>
			memory[index] -= 1;
		case operation::IN =>
			match (io::read(in, memory[index..index + 1])) {
			case let e: io::error =>
				fmt::fatal(io::strerror(e));
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
			io::write(out, [memory[index]])!;
		case operation::START =>
			abort("looping not implemented yet");
		case operation::END =>
			abort("looping not implemented yet");
		};
	};
};

// Converts a Brainfuck [[error]] into a user-friendly string.
export fn strerror(e: error) str = {
	match (e) {
	case nmaa =>
		return "Attempted to access negative memory";
	case unexpected =>
		abort("strerror: unexpected (loops) not yet implemented");
	};
};
