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


module identify_gamecube_games;



string[string] getGameCubeGameInfo(string game_file) {
	import std.stdio : File, stdout;
	import std.uni : toLower;
	import std.path : absolutePath;
	import std.bitmanip : peek;
	import std.system : Endian;
	import std.string : format, strip, chomp;
	import std.stdint : uint32_t;

	// Make sure the database is loaded
	if (! g_is_db_loaded) {
		// client/identify_gamecube_games/
		g_official_us_db = loadJson("db_gamecube_official_us.json");
		g_official_au_db = loadJson("db_gamecube_official_au.json");
		g_official_eu_db = loadJson("db_gamecube_official_eu.json");
		g_official_jp_db = loadJson("db_gamecube_official_jp.json");
		g_official_ko_db = loadJson("db_gamecube_official_ko.json");
		g_is_db_loaded = true;
	}

	// Make sure the file is a GameCube game
	if (! isGameCubeFile(game_file)) {
		throw new Exception("Not a known GameCube file type.");
	}

	// Get the full file name
	string full_entry = absolutePath(game_file);
	ubyte[256] small_buffer;

	// Open the game file
	auto f = File(full_entry, "r");
	scope (exit) f.close();

	// Get the file size
	long file_size = f.size();

	// Read the header
	ubyte[] header = cast(ubyte[]) f.rawRead(small_buffer).dup;
	string header_str = cast(string) header;

	uint32_t mime_type = peek!(uint32_t, Endian.bigEndian)(header, 0x1c);
	if (mime_type != 0xC2339F3D) {
		throw new Exception("Not a GameCube disk file.");
	}

	string serial_number = header_str[0 .. 4].strip();
	string sloppy_title = header_str[32 .. 32 + 32].chomp("\0");

	// Get the region from the game code
	char header_region = serial_number[3];
	string region;
	switch (header_region) {
	 	case 'D': region = "EUR"; break;
	 	case 'E': region = "USA"; break;
	 	case 'F': region = "EUR"; break;
	 	case 'I': region = "EUR"; break;
	 	case 'J': region = "JPN"; break;
	 	case 'K': region = "KOR"; break;
	 	case 'P': region = "EUR"; break;
	 	case 'R': region = "EUR"; break;
	 	case 'S': region = "EUR"; break;
	 	case 'T': region = "TAI"; break;
	 	case 'U': region = "AUS"; break;
		default:
			throw new Exception("Unknown region: %s".format(header_region));
	}

	serial_number = "DOL-%s-%s".format(serial_number, region);

	// Look up the proper name and vague region
	string title = null;
	string vague_region = null;
	if (serial_number in g_official_au_db) {
		vague_region = "AUS";
		title = g_official_au_db[serial_number];
	} else if (serial_number in g_official_eu_db) {
		vague_region = "EUR";
		title = g_official_eu_db[serial_number];
	} else if (serial_number in g_official_jp_db) {
		vague_region = "JPN";
		title = g_official_jp_db[serial_number];
	} else if (serial_number in g_official_ko_db) {
		vague_region = "KOR";
		title = g_official_ko_db[serial_number];
	} else if (serial_number in g_official_us_db) {
		vague_region = "USA";
		title = g_official_us_db[serial_number];
	}

	// Skip if unknown serial number
	if (! title || ! vague_region) {
		throw new Exception("Failed to find game in database.");
	}

	string[string] retval = [
		"serial_number" : serial_number,
		"region" : vague_region,
		"title" : title,
	];

	return retval;
}

private:

bool isGameCubeFile(string game_file) {
	import std.uni : toLower;
	import std.path : extension;
	import std.file : isFile;

	// Skip if not file
	if (! isFile(game_file)) {
		return false;
	}

	// Skip if not a usable file
	const string[] good_exts = [".iso", ".gcm"];
	string ext = toLower(extension(game_file));
	foreach(good_ext ; good_exts) {
		if (ext == good_ext) {
			return true;
		}
	}

	return false;
}

string[string] loadJson(string file_name) {
	import std.file : read;
	import std.json : parseJSON;

	// Read the json file
	ubyte[] data = cast(ubyte[]) read(file_name);

	// Strip the comments and load the json into the map
	data = cast(ubyte[]) stripJsonComments(cast(string) data);
	auto j = parseJSON(cast(char[])data);

	// Copy the data from json to an associative array
	string[string] load_into;
	foreach (serial_number, info ; j.object) {
		load_into[serial_number] = info.str;
	}

	return load_into;
}

string stripJsonComments(string data) {
	import std.string : split;
	import std.array : join;
	import std.algorithm.searching : canFind;

	string[] lines = data.split("\r\n");
	string[] new_data;
	foreach (line ; lines) {
		if (! line.canFind("/*") && ! line.canFind("*/")) {
			new_data ~= line;
		}
	}

	return new_data.join("\r\n");
}

bool g_is_db_loaded = false;
string[string] g_official_us_db;
string[string] g_official_au_db;
string[string] g_official_eu_db;
string[string] g_official_jp_db;
string[string] g_official_ko_db;


void printInfo(string path, string[string] info) {
	import std.stdio : stdout;

	stdout.writefln("path: %s", path);
	stdout.writefln("title: %s", info["title"]);
	stdout.writefln("region: %s", info["region"]);
	stdout.writefln("serial_number: %s", info["serial_number"]);
	stdout.flush();
}

int main(string[] args) {
	import std.stdio : stdout;
	import std.file : dirEntries, SpanMode;

	string games_root = "C:/Users/matt/Desktop/GameCube";
	auto entries = dirEntries(games_root, SpanMode.depth);
	foreach (entry ; entries) {
		// Skip if not a GameCube game
		if (! isGameCubeFile(entry)) {
			continue;
		}

		string[string] info = getGameCubeGameInfo(entry);
		printInfo(entry, info);
	}

	return 0;
}
