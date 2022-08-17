// Copyright (c) 2022 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: MPL-2.0
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use fmt;
use os;

use brainfuck;

export fn main() void = {
	if (len(os::args) != 2) {
		fmt::fatalf("usage: {} <programfile>", os::args[0]);
	};
	const program = brainfuck::load(os::args[1]);
	defer free(program);
	match (brainfuck::run(program)) {
	case let e: brainfuck::error =>
		fmt::fatalf("fatal: {}", brainfuck::strerror(e));
	case void => void;
	};
};
