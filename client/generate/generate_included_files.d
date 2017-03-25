// Copyright (c) 2015-2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// emulators-online is a HTML based front end for video game console emulators
// It uses the GNU AGPL 3 license
// It is hosted at: https://github.com/workhorsy/emulators-online
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

import std.conv;
import std.stdio;
import std.file;
import std.string;
import std.base64;
import std.zlib;
import std.process;
import std.array : appender;
import cbor;


void CompressWith7zip(string in_file, string out_file) {
	import std.algorithm;
	import std.array;

	// Get the command and arguments
	const string[] command = [
		"../../7za.exe",
		"a",
		"-t7z",
		"-m0=lzma2",
		"-mx=9",
		"%s".format(out_file),
		"%s".format(in_file),
	];

	// Run the command and wait for it to complete
	auto pipes = pipeProcess(command, Redirect.stdout | Redirect.stderr);
	int status = wait(pipes.pid);
/*
	string[] result_stdout = pipes.stdout.byLine.map!(l => l.idup).array();
	string[] result_stderr = pipes.stderr.byLine.map!(l => l.idup).array();
	stdout.writefln("!!! stdout:%s", result_stdout);
	stdout.writefln("!!! stderr:%s", result_stderr);
*/
	if (status != 0) {
		stderr.writefln("Failed to run command: %s\r\n", "7za.exe");
	}
}

int main() {
	// Generate a file that will generate everything
	auto output = std.stdio.File("client/generated/generated_files.d", "w");
	output.write("module Generated;\r\n\r\n");

	// Get a list of all the files to store
	const string[] file_names = [
		"unrar.exe",
		"index.html",
		"static/default.css",
		"static/emulators_online.js",
		"static/favicon.ico",
		"static/file_uploader.js",
		"static/input.js",
		"static/pako.min.js",
		"static/jquery-3.2.0.min.js",
		"static/web_socket.js",
		"client/identify_dreamcast_games/db_dreamcast_official_eu.json",
		"client/identify_dreamcast_games/db_dreamcast_official_jp.json",
		"client/identify_dreamcast_games/db_dreamcast_official_us.json",
		"client/identify_dreamcast_games/db_dreamcast_unofficial.json",
		"client/identify_games/db_playstation2_official_as.json",
		"client/identify_games/db_playstation2_official_au.json",
		"client/identify_games/db_playstation2_official_eu.json",
		"client/identify_games/db_playstation2_official_jp.json",
		"client/identify_games/db_playstation2_official_ko.json",
		"client/identify_games/db_playstation2_official_us.json",
		//"client/identify_games/identify_games.exe",
		"licenses/license_7zip",
		"licenses/license_emulatos_online",
		"licenses/license_identify_dreamcast_games",
		"licenses/license_identify_playstation2_games",
		"licenses/license_iso9660",
		"licenses/license_py_read_udf",
		"licenses/license_unrar",
	];

	// Read the files into an array
	byte[][string] file_map;
	foreach (file_name ; file_names) {
		// Read the file to a string
		byte[] data = cast(byte[]) std.file.read(file_name);

		// Put the file string into the array
		file_map[file_name] = data;
	}

	// Convert the array to a blob
	auto buffer = appender!(ubyte[])();
	encodeCbor(buffer, file_map);

	// Write the blob to file
	std.file.write("client/generated/blob", buffer.data);
	//buffer = null;

	// Compress the blob to file
	std.file.chdir("client/generated");
	CompressWith7zip("blob", "blob.7z");
	std.file.chdir("../..");

	// Read the compressed blob from file
	ubyte[] file_data = cast(ubyte[]) std.file.read("client/generated/blob.7z");

	// Base64 the compressed blob
	ubyte[] base64ed_data = cast(ubyte[]) Base64.encode(file_data);

	// Write the files generating function
	output.write("string GetCompressedFiles() {\r\n");
	output.write("    return \"");
	output.write(base64ed_data);
	output.write("\"\r\n");
	output.write("}\r\n");

	// Read 7zip into an array
	file_data = cast(ubyte[]) std.file.read("7za.exe");

	// Convert the 7zip array to a blob
	buffer = appender!(ubyte[])();
	encodeCbor(buffer, file_data);

	// Compress the blob
	ubyte[] zlibed_data = std.zlib.compress(buffer.data, 9);

	// Base64 the compressed blob
	base64ed_data = cast(ubyte[]) Base64.encode(zlibed_data);

	// Write the 7zip generating function
	output.write("string GetCompressed7zip() {\r\n");
	output.write("    return \"");
	output.write(base64ed_data);
	output.write("\"\r\n");
	output.write("}\r\n");

	// Close the file
	output.close();

	return 0;
}
