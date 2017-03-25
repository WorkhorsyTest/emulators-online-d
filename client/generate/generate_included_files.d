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

import std.stdio;
import std.file;

version (linux) {
	immutable string Exe7Zip = "7za";
}
version (Windows) {
	immutable string Exe7Zip = "7za.exe";
}

enum CompressionType {
	Zlib,
	Lzma,
}

ubyte[] ToCompressed(ubyte[] blob, CompressionType compression_type) {
	final switch (compression_type) {
		case CompressionType.Lzma:
			import std.algorithm;
			import std.array;
			import std.process;
			import std.string;
			import std.path;

			string blob_file = [std.file.tempDir(), "blob"].join(std.path.dirSeparator);
			string zip_file = [std.file.tempDir(), "blob.7z"].join(std.path.dirSeparator);
/*
			stdout.writefln("blob_file; %s", blob_file);
			stdout.writefln("zip_file; %s", zip_file);
*/

			// Write the blob to file
			std.file.write(blob_file, blob);

			// Get the command and arguments
			const string[] command = [
				Exe7Zip,
				"a",
				"-t7z",
				"-m0=lzma2",
				"-mx=9",
				"%s".format(zip_file),
				"%s".format(blob_file),
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
				stderr.writefln("Failed to run command: %s\r\n", Exe7Zip);
			}

			// Read the compressed blob from file
			ubyte[] file_data = cast(ubyte[]) std.file.read(zip_file);

			// Delete the temp files
			std.file.remove(blob_file);
			std.file.remove(zip_file);

			return file_data;
	case CompressionType.Zlib:
		import std.zlib;
		ubyte[] zlibed_data = std.zlib.compress(blob, 9);
		return zlibed_data;
	}
}

ubyte[] ToCompressedBase64(T)(T thing, CompressionType compression_type) {
	import std.array : appender;
	import cbor;
	import std.base64;

	// Convert the thing to a blob
	auto buffer = appender!(ubyte[])();
	encodeCbor(buffer, thing);
	ubyte[] blob = buffer.data;

	// Compress the blob
	ubyte[] compressed_bob = ToCompressed(blob, compression_type);

	// Base64 the compressed blob
	ubyte[] base64ed_compressed_blob = cast(ubyte[]) Base64.encode(compressed_bob);

	return base64ed_compressed_blob;
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
	ubyte[] base64ed_data = ToCompressedBase64(file_map, CompressionType.Lzma);

	// Write the files generating function
	output.write("string GetCompressedFiles() {\r\n");
	output.write("    return \"");
	output.write(base64ed_data);
	output.write("\"\r\n");
	output.write("}\r\n");

	// Read 7zip into an array
	ubyte[] file_data = cast(ubyte[]) std.file.read(Exe7Zip);

	// Convert the 7zip array to a blob
	base64ed_data = ToCompressedBase64(file_data, CompressionType.Zlib);

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
