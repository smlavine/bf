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
		fmt::fatalf("usage: {} <programfile>", os::args[0]);
	};

	const file = match (os::open(os::args[1])) {
	case let e: fs::error =>
		fmt::fatal(fs::strerror(e));
	case let f: io::file =>
		yield f;
	};
	defer match (io::close(file)) {
	case let e: io::error =>
		match (fmt::errorln("couldn't close {}: {}",
				os::args[1], io::strerror(e))) {
		case => void; // Ignore io::error
		};
	case void => void;
	};

	const program = brainfuck::load(file);
	defer free(program);

	match (brainfuck::run(program, os::stdin, os::stdout)) {
	case let e: brainfuck::error =>
		fmt::fatalf("fatal: {}", brainfuck::strerror(e));
	case void => void;
	};
};
