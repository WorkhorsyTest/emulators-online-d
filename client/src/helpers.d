// Copyright (c) 2015-2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// emulators-online is a HTML based front end for video game console emulators
// It uses the GNU AGPL 3 license
// It is hosted at: https://github.com/workhorsy/emulators-online-d
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


module helpers;

import std.stdio;

int g_direct_x_version = -1;

string[] glob(string path, string pattern, bool is_shallow) {
	import std.file;
	import std.path;
	import std.range.primitives;
	import std.stdio;

	string[] matches;
	string[] to_search = [path];
	while (to_search.length > 0) {
		string current = to_search[0];
		std.range.primitives.popFront(to_search);
		try {
			auto entries = std.file.dirEntries(current, SpanMode.shallow);
			foreach (entry ; entries) {
				if (! is_shallow && std.file.isDir(entry.name)) {
					to_search ~= entry.name;
				} else {
					string base_name = std.path.baseName(entry.name);
					if (std.path.globMatch(base_name, pattern)) {
						matches ~= entry.name;
					}
				}
			}
		} catch (Throwable err) {

		}
	}


	return matches;
}

void TryRemovingFileOnExit(string file_name) {
	import std.file;

	if (std.file.exists(file_name)) {
		try {
			std.file.remove(file_name);
		} catch (FileException err) {
			// Ignore any error
		}
	}
};

int GetDirectxVersion() {
	int int_version = -1;

	version (Windows) {
		import std.process;
		import std.file;
		import std.stdio;
		import std.string;

		// Try to remove any generated files when the function exists
		scope (exit) TryRemovingFileOnExit("directx_info.txt");

		const string[] command = [
			"dxdiag.exe",
			"/t",
			"directx_info.txt",
		];

		// Run the command and wait for it to complete
		auto pipes = pipeProcess(command, Redirect.stdout | Redirect.stderr);
		int status = wait(pipes.pid);

		if (status != 0) {
			stderr.writefln("Failed to determine DirectX version"); stderr.flush();
		}

		string string_data = cast(string) std.file.read("directx_info.txt");
		string raw_version = string_data.split("DirectX Version: ")[1].split("\r\n")[0];

		// Get the DirectX version
		if (raw_version.indexOf("12") != -1) {
			int_version = 12;
		} else if (raw_version.indexOf("11") != -1) {
			int_version = 11;
		} else if (raw_version.indexOf("10") != -1) {
			int_version = 10;
		} else if (raw_version.indexOf("9") != -1) {
			int_version = 9;
		} else {
			stderr.writefln("Failed to determine DirectX version"); stderr.flush();
		}
	}

	return int_version;
}
