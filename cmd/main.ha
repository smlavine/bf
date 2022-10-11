// Copyright (c) 2022 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use fmt;
use fs;
use getopt;
use io;
use os;

use brainfuck;

export fn main() void = {
	const help: []getopt::help = [
		"Brainfuck interpreter",
		('v', "Display version"),
		"program-file",
	];
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		switch (cmd.opts[i].0) {
		case 'v' =>
			fmt::printfln("bf v{}", brainfuck::VERSION)!;
			return;
		};
	};

	if (len(cmd.args) != 1) {
		getopt::printusage(os::stderr, os::args[0], help);
		os::exit(1);
	};

	const path = cmd.args[0];
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
	case let e: brainfuck::error =>
		fmt::fatalf("{}: {}", os::args[0], brainfuck::strerror(e));
	case let p: brainfuck::program =>
		yield p;
	};
	defer free(program);

	match (brainfuck::run(program, os::stdin, os::stdout)) {
	case let e: brainfuck::error =>
		fmt::fatalf("{}: {}", os::args[0], brainfuck::strerror(e));
	case void => void;
	};
};
