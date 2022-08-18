// Copyright (c) 2022 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use fmt;
use fs;
use io;
use os;

use brainfuck;

export fn main() void = {
	if (len(os::args) != 2) {
		fmt::fatalf("Usage: {} <programfile>", os::args[0]);
	};

	const path = os::args[1];
	const file = match (os::open(path)) {
	case let e: fs::error =>
		fmt::fatalf("{}: Couldn't open {}: {}",
			os::args[0], path, fs::strerror(e));
	case let f: io::file =>
		yield f;
	};
	defer match (io::close(file)) {
	case let e: io::error =>
		fmt::errorln("{}: Couldn't close {}: {}", os::args[0],
			path, io::strerror(e)): void; // Ignore io::error
	case void => void;
	};

	const program = match (brainfuck::load(file)) {
	case let e: brainfuck::load_error =>
		fmt::fatalf("{}: {}", os::args[0], brainfuck::strerror(e));
	case let p: brainfuck::program =>
		yield p;
	};
	defer free(program);

	match (brainfuck::run(program, os::stdin, os::stdout)) {
	case let e: brainfuck::run_error =>
		fmt::fatalf("{}: {}", os::args[0], brainfuck::strerror(e));
	case void => void;
	};
};
