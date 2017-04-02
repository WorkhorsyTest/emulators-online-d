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


module worker;

import std.concurrency;
static import vibe.vibe;
import std.stdio;
import std.json;
import encoder;

// g_db is accessed like g_db[console][game][binary_name]
Variant[string][string][string] g_db;
long[string][string] g_file_modify_dates;

void Send(Tid tid, string message) {
	send(tid, message);
}

Tid Start() {
	Tid tid = spawn(&backgroundThread, thisTid);

	auto val = vibe.vibe.async({
		run();
		return 0;
	});

	return tid;
}

private void run() {
	import core.time;

	while (true) {
		receiveTimeout(1.seconds,
			(string m) { vibe.vibe.logInfo("FIXME: Got message:%s", m); },
			(Variant v) { vibe.vibe.logWarn("Received some other type."); }
		);
	}
}

private void backgroundThread(Tid ownerTid) {
	while (true) {
		receive((string msg) {
			JSONValue message_map;
			message_map = DecodeMessage(msg);
			string action = message_map["action"].str;

			switch (action) {
				case "search_game_directory":
					actionSearchGameDirectory(message_map);
					break;
				default:
					break;
			}
		});
	}

	//string response = "FIXME: the response goes here";
	//send(ownerTid, response);
}

private void actionSearchGameDirectory(ref JSONValue message_map) {
	import std.file;
	import std.string;
	import std.path;
	import std.datetime;
	import std.array;
	import std.stdio;
	import helpers;
	import compress;

	string directory_name = message_map["directory_name"].str;
	string console = message_map["console"].str;

	// Get the path for this console
	string path_prefix;
	switch (console) {
		case "dreamcast":
			path_prefix = "images/Sega/Dreamcast";
			break;
		case "playstation2":
			path_prefix = "images/Sony/Playstation2";
			break;
		default:
			vibe.vibe.logFatal("Unknown console type: %s", console);
			return;
	}

	// Get the total number of files
	float total_files = 0.0f;
	auto entries = std.file.dirEntries(directory_name, SpanMode.breadth);
	foreach (entry ; entries) {
		if (std.file.isFile(entry)) {
			total_files++;
		}
	}

	// Walk through all the directories
	float done_files = 0.0f;
	entries = std.file.dirEntries(directory_name, SpanMode.breadth);
	foreach (file_info ; entries) {
		// Get the full path
		string entry = file_info;
		entry = absolutePath(entry);
		entry = entry.replace("\\", "/");

		// Get the percentage of the progress looping through files
		float percentage = (done_files / total_files) * 100.0f;
		//a_task.percentage = percentage;
		//FIXME: channel_task_progress <- a_task;
		done_files += 1.0f;

		// Skip if the the entry is not a file
		if (! std.file.isFile(entry)) {
			continue;
		}

		// Skip if the game file has not been modified
		long old_modify_date = 0;
		if ((entry in g_file_modify_dates[console]) != null) {
			old_modify_date = g_file_modify_dates[console][entry];
		}
		auto modify_date = std.datetime.stdTimeToUnixTime(timeLastModified(entry));
		if (modify_date == old_modify_date) {
			continue;
		} else {
			g_file_modify_dates[console][entry] = modify_date;
		}

		// Get the game info
		string[string] info;
/*
		exec.Cmd cmd;
		if (console == "dreamcast") {
			cmd = exec.Command("client/identify_games/identify_games.exe", console, entry);
		} else if (console == "playstation2") {
			cmd = exec.Command("client/identify_games/identify_games.exe", console, entry);
		} else {
			throw new Exception("Unexpected console: %s".format(console));
		}

		// Run the command and get the info for this game
		bytes.Buffer out_buffer;
		cmd.Stdout = &out_buffer;
		err = cmd.Run();
		if (err != null) {
			fmt.Printf("Failed to get game info for file: %s\r\n", entry);
			return null;
		}
		byte[] out_bytes = out_buffer.Bytes();
		if (out_bytes.length > 0) {
			err = json.Unmarshal(out_bytes, &info);
			if (err != null) {
				fmt.Printf("Failed to convert json to map: %s\r\n%s\r\n", err, string(out_bytes));
				return null;
			}
		} else {
			return null;
		}
		if (err != null) {
			fmt.Printf("Failed to find info for game \"%s\"\r\n%s\r\n", entry, err);
			return null;
		}
		fmt.Printf("getting game info: %s\r\n", cast(string) info["title"]);
		info["file"] = entry;
*/
		// Save the info in the db
		if (info != null) {
			string title = cast(string) info["title"];
			string clean_title = helpers.SanitizeFileName(title);

			// Initialize the db for this console if needed
			if ((console in g_db) == null) {
				g_db[console].clear();//FIXME: make(map[string]map[string]object);
			}

			g_db[console][title] = [
				"path" : "%s/%s/".format(path_prefix, clean_title).CleanPath(),
				"binary" : absolutePath(info["file"]),
				"bios" : "",
				"images" : [],
				"developer" : "",
				"publisher" : "",
				"genre" : ""
			];

			if (("developer" in info) != null) {
				g_db[console][title]["developer"] = info["developer"];
			}

			if (("publisher" in info) != null) {
				g_db[console][title]["publisher"] = info["publisher"];
			}

			if (("genre" in info) != null) {
				g_db[console][title]["genre"] = info["genre"];
			}

			// Get the images
			string image_dir = "%s/%s/".format(path_prefix, title);
			string[] expected_images = ["title_big.png", "title_small.png"];
			foreach (img ; expected_images) {
				if (! std.file.isDir(image_dir)) {
					string image_file = "%s%s".format(image_dir, img);
					if (std.file.isFile(image_file)) {
						string[] images = g_db[console][title]["images"].get!(string[]);
						images ~= image_file;
						g_db[console][title]["images"] = images;
					}
				}
			}
		}
	}

	// Send the updated game db to the browser
	ubyte[] value = compress.ToCompressedBase64(g_db, CompressionType.Zlib);

	object[string] message = [
		"action" : "set_db",
		"value" : value,
	];
	WebSocketSend(&message);

	//// Write the db cache file
	//f, err := os.Create(fmt.Sprintf("cache/game_db_%s.json", console))
	//defer f.Close()
	//if (err != null) {
	//	fmt.Printf("Failed to open cache file: %s\r\n", err)
	//	return err
	//}
	//jsoned_data, err := json.MarshalIndent(db[console], "", "\t")
	//if (err != null) {
	//	fmt.Printf("Failed to convert db to json: %s\r\n", err)
	//	return err
	//}
	//f.Write(jsoned_data)

	// Write the modify dates cache file
	auto f = File("cache/file_modify_dates_%s.json".format(console), "w");
	scope (exit) f.close();
/*
	if (err != null) {
		fmt.Printf("Failed to open file modify dates file: %s\r\n", err);
		return err;
	}

	string jsoned_data = json.MarshalIndent(g_file_modify_dates[console], "", "\t");
	if (err != null) {
		fmt.Printf("Failed to convert file_modify_dates to json: %s\r\n", err);
		return err;
	}
	f.Write(jsoned_data);

	fmt.Printf("Done getting games from directory.");

	a_task.percentage = 100.0f;
	// FIXME: channel_task_progress <- a_task;

	// Signal that we are done
	// FIXME: channel_is_done <- true;
*/
}
