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
import compress;

int main() {
	std.file.chdir("../..");

	// Generate a file that will generate everything
	auto output = std.stdio.File("client/wrapped_client/wrapped.d", "w");
	output.write("\r\n\r\n");

	// Get a list of all the files to store
	const string[] file_names = [
		"README.md",
		"TODO.md",
		"emulators_online_client",
	];

	// Read the files into an array
	ubyte[][] file_blobs;
	foreach (file_name ; file_names) {
		// Read the file to a string
		file_blobs ~= cast(ubyte[]) std.file.read(file_name);
	}

	// Convert the array to a compressed blob
	ubyte[] compressed_blobs = ToCompressedBase64(file_blobs, CompressionType.Zlib);

	// Write the files generating function
	output.write("static immutable string[] g_file_names = \r\n");
	output.write(file_names);
	output.write(";\r\n\r\n");

	output.write("static immutable ubyte[] g_compressed_blobs = \r\n");
	output.write(compressed_blobs);
	output.write(";\r\n\r\n");

	output.write("int main() {\r\n");
	output.write("	import compress;\r\n");
	output.write("\r\n");
	output.write("	string[] file_names = cast(string[]) g_file_names;\r\n");
	output.write("	ubyte[] blob = cast(ubyte[]) g_compressed_blobs;\r\n");
	output.write("	UncompressFiles(file_names, blob);\r\n");
	output.write("\r\n");
	output.write("	return 0;\r\n");
	output.write("}\r\n");

	// Close the file
	output.close();

	return 0;
}
