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

module identify_dreamcast_games;

import std.stdio;


private const long BUFFER_SIZE = 1024 * 1024 * 5;
private ubyte[BUFFER_SIZE] g_big_buffer;
private bool g_is_db_loaded = false;
private string[string][string] g_unofficial_db;
private string[string][string] g_official_us_db;
private string[string][string] g_official_eu_db;
private string[string][string] g_official_jp_db;


private string stripComments(string data) {
	import std.string;
	import std.array;
	import std.algorithm.searching;

	string[] lines = data.split("\r\n");
	string[] new_data;
	foreach (line ; lines) {
		if (! line.canFind("/*") && ! line.canFind("*/")) {
			new_data ~= line;
		}
	}

	return new_data.join("\r\n");
}

private string readBlobAt(File file, long start_address, ubyte[] buffer, size_t size) {
	file.seek(start_address, 0);

	ubyte[] buffer_to_use = buffer[0 .. size];
	ubyte[] used_buffer = file.rawRead(buffer_to_use);

	if (size < used_buffer.length) {
		throw new Exception("Read size was less than the desired size.");
	}
	return cast(string) buffer[0 .. size];
}

private string[string][string] loadJson(string file_name) {
	import std.file;
	import std.json;

	// Read the json file
	ubyte[] data = cast(ubyte[]) std.file.read(file_name);

	// Strip the comments and load the json into the map
	data = cast(ubyte[]) stripComments(cast(string) data);
	auto j = parseJSON(data);

	// Copy the data from json to an associative array
	string[string][string] load_into;
	foreach (serial_number, info ; j.object) {
		foreach (field, value ; info.object) {
			load_into[serial_number][field] = value.str;
		}
	}

	return load_into;
}

private void fixGamesWithSameSerialNumber(File f, ref string title, ref string serial_number) {
	if (serial_number == "T-8111D-50") {
		if (title == "ECW HARDCORE REVOLUTION") { // EU ECW Hardcore Revolution
			title = "ECW Hardcore Revolution";
			serial_number = "T-8111D-50";
		} else if (title == "DEAD OR ALIVE 2") { // EU Dead or Alive 2
			title = "Dead or Alive 2";
			serial_number = "T-8111D-50";
		}
	} else if (serial_number == "T-8101N") {
		if (title == "QUARTERBACK CLUB 2000") { //US NFL Quarterback Club 2000
			title = "NFL Quarterback Club 2000";
			serial_number = "T-8101N";
		} else if (title == "JEREMY MCGRATH SUPERCROSS 2000") { //US Jeremy McGrath Supercross 2000
			title = "Jeremy McGrath Supercross 2000";
			serial_number = "T-8101N";
		}
	}
	/*
	else if serial_number == "T9706D  61":
		EU 18 Wheeler: American Pro Trucker
		EU 4-Wheel Thunder

	else if serial_number == "T1214M":
		JP BioHazard Code: Veronica Trial Edition
		JP BioHazard 2

	else if serial_number == "MK-51062":
		US Skies of Arcadia
		US NFL 2K1

	else if serial_number == "MK-51168":
		US NFL 2K2
		US Confidential Mission
	else if serial_number == "T30001M":
		JP D2 Shock
		JP Kaze no Regret Limited Edition
	else if serial_number == "MK51038  50":
		EU Sega WorldWide Soccer 2000 Euro Edition
		EU Zombie Revenge
	*/
}

private void fixGamesThatAreMislabeled(File f, ref string title, ref string serial_number) {
	ubyte[30] buffer;
	switch (serial_number) {
		case "T1402N": // Mr. Driller
			if (readBlobAt(f, 0x159208, buffer, 12) == "DYNAMITE COP") {
				title = "Dynamite Cop!";
				serial_number = "MK-51013";
			}
			break;
		case "MK-51035": // Crazy Taxi
			if (readBlobAt(f, 0x1617E652, buffer, 9) == "Half-Life") {
				title = "Half-Life";
				serial_number = "T0000M";
			} else if (readBlobAt(f, 0x1EA78B5, buffer, 10) == "Shadow Man") {
				title = "Shadow Man";
				serial_number = "T8106N";
			}
			break;
		case "T43903M": // Culdcept II
			if (readBlobAt(f, 0x264E1E5D, buffer, 10) == "CHAOSFIELD") {
				title = "Chaos Field";
				serial_number = "T47801M";
			}
			break;
		case "T0000M": // Unnamed
			if (readBlobAt(f, 0x557CAB0, buffer, 13) == "BALL BREAKERS") {
				title = "Ball Breakers";
				serial_number = "T0000M";
			} else if (readBlobAt(f, 0x4BD5EE5, buffer, 6) == "TOEJAM") {
				title = "ToeJam and Earl 3";
				serial_number = "T0000M";
			}
			break;
		case "T0000": // Unnamed
			if (readBlobAt(f, 0x162E20, buffer, 15) == "Art of Fighting") {
				title = "Art of Fighting";
				serial_number = "T0000";
			} else if (readBlobAt(f, 0x29E898B0, buffer, 17) == "Art of Fighting 2") {
				title = "Art of Fighting 2";
				serial_number = "T0000";
			} else if (readBlobAt(f, 0x26D5BCA4, buffer, 17) == "Art of Fighting 3") {
				title = "Art of Fighting 3";
				serial_number = "T0000";
			} else if (readBlobAt(f, 0x295301F0, buffer, 5) == "Redux") {
				title = "Redux: Dark Matters";
				serial_number = "T0000";
			}
			break;
		case "MK-51025": // NHL 2K1
			if (readBlobAt(f, 0x410CA8, buffer, 14) == "READY 2 RUMBLE") {
				title = "Ready 2 Rumble Boxing";
				serial_number = "T9704N";
			}
			break;
		case "T36804N": // Walt Disney World Quest: Magical Racing Tour
			if (readBlobAt(f, 0x245884, buffer, 6) == "MakenX") {
				title = "Maken X";
				serial_number = "MK-51050";
			}
			break;
		case "RDC-0117": // The king of Fighters '96 Collection (NEO4ALL RC4)
			if (readBlobAt(f, 0x159208, buffer, 16) == "BOMBERMAN ONLINE") {
				title = "Bomberman Online";
				serial_number = "RDC-0120";
			}
			break;
		case "RDC-0140": // Dead or Alive 2
			if (readBlobAt(f, 0x15639268, buffer, 13) == "CHUCHU ROCKET") {
				title = "ChuChu Rocket!";
				serial_number = "RDC-0139";
			}
			break;
		case "T19724M": // Pizzicato Polka: Suisei Genya
			if (readBlobAt(f, 0x3CA16B8, buffer, 7) == "DAYTONA") {
				title = "Daytona USA";
				serial_number = "MK-51037";
			}
			break;
		case "MK-51049": // ChuChu Rocket!
			if (readBlobAt(f, 0xC913DDC, buffer, 13) == "HYDRO THUNDER") {
				title = "Hydro Thunder";
				serial_number = "T9702N";
			} else if (readBlobAt(f, 0x2D096802, buffer, 17) == "MARVEL VS. CAPCOM") {
				title = "Marvel vs. Capcom 2";
				serial_number = "T1212N";
			} else if (readBlobAt(f, 0x1480A730, buffer, 13) == "POWER STONE 2") {
				title = "Power Stone 2";
				serial_number = "T-1211N";
			}
			break;
		case "T44304N": // Sports Jam
			string name = readBlobAt(f, 0x157FA8, buffer, 9);
			if (name == "OUTRIGGER") {
				title = "OutTrigger: International Counter Terrorism Special Force";
				serial_number = "MK-51102";
			}
			break;
		case "MK-51028": // Virtua Striker 2
			if (readBlobAt(f, 0x1623B0, buffer, 12) == "zerogunner 2") {
				title = "Zero Gunner 2";
				serial_number = "MK-51028";
				//return "OutTrigger: International Counter Terrorism Special Force", "MK-51102"
			}
			break;
		case "T1240M": // BioHazard Code: Veronica Complete
			string name = readBlobAt(f, 0x157FAD, buffer, 14);
			if (name == "BASS FISHING 2") {
				title = "Sega Bass Fishing 2";
				serial_number = "MK-51166";
			}
			break;
		case "MK-51100": // Phantasy Star Online
			string name = readBlobAt(f, 0x52F28A8, buffer, 26);
			if (name == "Phantasy Star Online Ver.2") {
				title = "Phantasy Star Online Ver. 2";
				serial_number = "MK-51166";
			}
			break;
		default:
			break;
	}
}

private long locateStringInFile(File f, long file_size, ubyte[] buffer, string string_to_find) {
	import std.string;
	import std.algorithm.searching;

	long string_length = string_to_find.length;
	f.seek(0, 0);
	while (true) {
		// Read into the buffer
		ubyte[] rom_data = cast(ubyte[]) f.rawRead(buffer);

		// Check for the end of the file
		if (rom_data.length < 1) {
			break;
		}

		// Figure out if we need an offset
		long file_pos = f.tell();
		bool use_offset = false;
		if (file_pos > string_length && file_pos < file_size) {
			use_offset = true;
		}

		// Get the string to find location
		long index = std.algorithm.searching.countUntil(rom_data, string_to_find);
		if (index > -1) {
			long string_file_location = (file_pos - rom_data.length) + index;
			return string_file_location;
		}

		// Move back the length of the string to find
		// This is done to stop the string to find from being spread over multiple buffers
		if (use_offset) {
			f.seek(file_pos - string_length, 0);
		}
	}

	return -1;
}

private string getTrack01FromGdiFile(string file_name, ubyte[] buffer) {
	import std.string;
	import std.path;
	import std.stdio;

	string path = dirName(file_name);

	auto f = File(file_name, "r");
	scope (exit) f.close();

	ubyte[] used_buffer = f.rawRead(buffer);

	string track = cast(string) used_buffer;
	string track_01_line = track.split("\r\n")[1];
	string track_01_file = track_01_line.split(" ")[4];
	track_01_file = [path, track_01_file].join(std.path.dirSeparator);
	return track_01_file;
}

void printInfo(string path, string[string] info) {
	stdout.writefln("path: %s", path);
	stdout.writefln("title: %s", info["title"]);
	stdout.writefln("disc_info: %s", info["disc_info"]);
	stdout.writefln("region: %s", info["region"]);
	stdout.writefln("serial_number: %s", info["serial_number"]);
	stdout.writefln("version: %s", info["version"]);
	stdout.writefln("boot: %s", info["boot"]);
	stdout.writefln("maker: %s", info["maker"]);
	stdout.writefln("developer: %s", info["developer"]);
	stdout.writefln("genre: %s", info["genre"]);
	stdout.writefln("publisher: %s", info["publisher"]);
	stdout.writefln("release_date: %s", info["release_date"]);
	stdout.writefln("sloppy_title: %s", info["sloppy_title"]);
	stdout.writefln("header_index: %s", info["header_index"]);
	stdout.flush();
}

bool IsDreamcastFile(string game_file) {
	import std.uni;
	import std.path;
	import std.file;

	// Skip if not file
	if (! std.file.isFile(game_file)) {
		return false;
	}

	// FIXME: Make it work with .mdf/.mds, .nrg, and .ccd/.img
	// Skip if not a usable file
	const string[] good_exts = [".cdi", ".gdi", ".iso"];
	string ext = std.uni.toLower(std.path.extension(game_file));
	foreach(good_ext ; good_exts) {
		if (ext == good_ext) {
			return true;
		}
	}

	return false;
}

string[string] GetDreamcastGameInfo(string game_file) {
	import std.uni;
	import std.path;
	import std.array;
	import std.string;
	import std.algorithm.mutation;

	// Make sure the database is loaded
	if (! g_is_db_loaded) {
		g_unofficial_db = loadJson("client/identify_dreamcast_games/db_dreamcast_unofficial.json");
		g_official_us_db = loadJson("client/identify_dreamcast_games/db_dreamcast_official_us.json");
		g_official_jp_db = loadJson("client/identify_dreamcast_games/db_dreamcast_official_jp.json");
		g_official_eu_db = loadJson("client/identify_dreamcast_games/db_dreamcast_official_eu.json");
		g_is_db_loaded = true;
	}

	// Make sure the file is a Dreamcast game
	if (! IsDreamcastFile(game_file)) {
		throw new Exception("Not a known Dreamcast file type.");
	}

	// Get the full file name
	string full_entry = absolutePath(game_file);

	// If it's a GDI file read track 01
	ubyte[256] small_buffer;
	if (std.uni.toLower(std.path.extension(full_entry)) == ".gdi") {
		full_entry = getTrack01FromGdiFile(full_entry, small_buffer);
	}

	// Open the game file
	auto f = File(full_entry, "r");
	scope (exit) f.close();

	// Get the file size
	long file_size = f.size();

	// Get the location of the header
	const string header_text = "SEGA SEGAKATANA SEGA ENTERPRISES";
	long index = locateStringInFile(f, file_size, g_big_buffer, header_text);

	// Throw if index not found
	if (index == -1) {
		throw new Exception("Failed to find Sega Dreamcast Header.");
	}

	// Read the header
	f.seek(index, 0);
	string header = cast(string) f.rawRead(small_buffer).dup;

	// Parse the header info
	size_t offset = header_text.length;
	string disc_info = header[offset + 5 .. offset + 5 + 11].strip();
	string region = header[offset + 14 .. offset + 14 + 10].strip();
	string serial_number = header[offset + 32 .. offset + 32 + 10].strip();
	string version_string = header[offset + 42 .. offset + 42 + 22].strip();
	string boot = header[offset + 64 .. offset + 64 + 16].strip();
	string maker = header[offset + 80 .. offset + 80 + 16].strip();
	string sloppy_title = header[offset + 96 .. $].strip();
	string title;
	string developer;
	string genre;
	string publisher;
	string release_date;

	// Remove trailing zeros
	if (serial_number.endsWith(" 00")) {
		serial_number = serial_number[0 .. -3].strip();
	}

	// Remove any spaces and dashes
	serial_number = serial_number.replace("-", "").replace(" ", "").strip();

/*
	stdout.writefln("offset: %s", offset);
	stdout.writefln("disc_info: %s", disc_info);
	stdout.writefln("region: %s", region);
	stdout.writefln("serial_number: %s", serial_number);
	stdout.writefln("version: %s", version_string);
	stdout.writefln("boot: %s", boot);
	stdout.writefln("marker: %s", maker);
	stdout.writefln("sloppy_title: %s", sloppy_title);
	stdout.writefln("index: %s", index);
*/
	// Check for different types of releases

	// Unofficial
	string[string] info;
	if ((serial_number in g_unofficial_db) != null) {
		info = g_unofficial_db[serial_number];
	// US
	} else if ((serial_number in g_official_us_db) != null) {
		info = g_official_us_db[serial_number];
	// Europe
	} else if ((serial_number in g_official_eu_db) != null) {
		info = g_official_eu_db[serial_number];
	// Japan
	} else if ((serial_number in g_official_jp_db) != null) {
		info = g_official_jp_db[serial_number];
	}

	if (info.length > 0) {
		title = info["title"];
		developer = info["developer"];
		genre = info["genre"];
		publisher = info["publisher"];
		release_date = info["release_date"];
	}

	// Check for games with the same serial number
	fixGamesWithSameSerialNumber(f, title, serial_number);

	// Check for mislabeled releases
	fixGamesThatAreMislabeled(f, title, serial_number);

	// Throw if the title is not found in the database
	if (title.length == 0) {
		throw new Exception("Failed to find game in database.");
	}

	string[string] retval = [
		"title" : title,
		"disc_info" : disc_info,
		"region" : region,
		"serial_number" : serial_number,
		"version" : version_string,
		"boot" : boot,
		"maker" : maker,
		"developer" : developer,
		"genre" : genre,
		"publisher" : publisher,
		"release_date" : release_date,
		"sloppy_title" : sloppy_title,
		"header_index" : "%d".format(index),
	];

	return retval;
}

int mainXXX(string[] args) {
	import std.file;
	import std.path;
	import std.stdio;
	import std.array;

	// Get the path of the current exe
	//string root = dirName(args[0]);


///*
	string games_root = "C:/Users/bob/Desktop/Dreamcast/";
	auto entries = std.file.dirEntries(games_root, SpanMode.depth);
	foreach (entry ; entries) {
		// Skip if not a Dreamcast game
		if (! IsDreamcastFile(entry)) {
			continue;
		}

		string[string] info = GetDreamcastGameInfo(entry);
		printInfo(entry, info);
	}

//*/
/*
	string path = "C:/Users/bob/Desktop/Dreamcast/Sonic Adventure 2/sonic_adventure_2.cdi";
	//path = "C:/Users/matt/Desktop/Dreamcast/18 Wheeler - American Pro Trucker/18 Wheeler - American Pro Trucker v1.500 (2001)(Sega)(NTSC)(US)[!].gdi"
	auto info = GetDreamcastGameInfo(path);


*/
	return 0;
}
