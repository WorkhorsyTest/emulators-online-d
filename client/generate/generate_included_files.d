// Copyright (c) 2015-2018 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
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


int main() {
	import compress : ToCompressedBase64, CompressionType, Exe7Zip, ExeUnrar;

	import std.stdio : File;
	import std.file : chdir, read;

	chdir("../..");

	// Generate a file that will generate everything
	auto output = File("client/generate/generated_files.d", "w");
	output.write("module Generated;\r\n\r\n");

	// Get a list of all the files to store
	const string[] file_names = [
		"static/index.html",
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
		byte[] data = cast(byte[]) read(file_name);

		// Put the file string into the array
		file_map[file_name] = data;
	}

	// Convert the array to a blob
	ubyte[] base64ed_data = ToCompressedBase64(file_map, CompressionType.Lzma);

	// Write the files generating function
	output.write("immutable byte[] GetCompressedFiles = \r\n");
	output.write(base64ed_data);
	output.write(";\r\n");

	// Read 7zip into an array
	ubyte[] file_data = cast(ubyte[]) read("tools/" ~ Exe7Zip);

	// Convert the 7zip array to a blob
	base64ed_data = ToCompressedBase64(file_data, CompressionType.Zlib);

	// Write the 7zip generating function
	output.write("immutable byte[] GetCompressed7zip = \r\n");
	output.write(base64ed_data);
	output.write(";\r\n");

	// Read Unrar into an array
	file_data = cast(ubyte[]) read("tools/" ~ ExeUnrar);

	// Convert the Unrar array to a blob
	base64ed_data = ToCompressedBase64(file_data, CompressionType.Zlib);

	// Write the Unrar generating function
	output.write("immutable byte[] GetCompressedUnrar = \r\n");
	output.write(base64ed_data);
	output.write(";\r\n");

	// Close the file
	output.close();

	return 0;
}
