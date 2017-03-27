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

module compress;

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

byte[] FromCompressed(byte[] data, CompressionType compression_type) {
	final switch (compression_type) {
		case CompressionType.Lzma:
			return [];
		case CompressionType.Zlib:
			import std.zlib;
			byte[] blob = cast(byte[]) std.zlib.uncompress(data);
			return blob;
	}
}

byte[] FromCompressedBase64(byte[] data, CompressionType compression_type) {
	import std.array : appender;
	import std.base64;

	// UnBase64 the blob
	byte[] compressed_blob = cast(byte[]) Base64.decode(data);

	// Uncompress the blob
	byte[] blob = FromCompressed(compressed_blob, compression_type);
	return blob;
}

T FromCompressedBase64(T)(byte[] data, CompressionType compression_type) {
	import cbor;

	// Uncompress the blob
	byte[] blob = FromCompressedBase64(compressed_blob, compression_type);

	// Convert the blob to the thing
	T thing = decodeCborSingle!T(blob);
	return thing;
}