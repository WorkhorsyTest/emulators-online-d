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
import std.string;
import std.base64;
import std.json;
import core.thread;
import vibe.vibe;
import compress;
import encoder;
import Generated;
import helpers;

bool g_websocket_needs_restart;

class LongRunningTask {
	string name;
	float percentage;
}

// g_db is accessed like g_db[console][game][binary_name]
string[string][string][string] g_db;
long[string][string] file_modify_dates;
LongRunningTask[string] long_running_tasks;
//helpers.Demul demul;
//helpers.PCSX2 pcsx2;

string[] g_consoles;

/*
string CleanPath(string file_path) {
	// Fix the backward slashes from Windows
	string new_path = file_path.replace("\\", "/", -1);

	// Strip off the Disc number
	if (new_path.contains(" [Disc")) {
		new_path = new_path.split(" [Disc")[0];
	}

	// Make sure it ends with a slash
	if (! new_path.HasSuffix("/")) {
		new_path += "/";
	}

	return new_path;
}

string AbsPath(string file_path) {
	string file_path = filepath.Abs(file_path);
	file_path = file_path.Replace("\\", "/", -1);
	return file_path;
}

void WebSocketSend(T)(T thing) {
	//fmt.Printf("<<< out %v\r\n", thing)

	// Convert the object to base64ed json
	string message;
	try {
		message = ToBase64Json(thing);
	} catch (Throwable err) {
		throw new Exception("Failed to encode websocket message: %s".format(err));
	}
	//fmt.Printf("message: %s\r\n", message)

	// Get the header
	string whole_message = "%d:%s".format(message.length, message);
	//fmt.Printf("whole_message: %s\r\n", whole_message)

	// Write the message
	byte[] buffer = cast(byte[]) whole_message;
	int write_len = g_ws.Write(buffer);
	if (err != null) {
		g_websocket_needs_restart = true;
		throw new Exception("Failed to write websocket message: %s".format(err));
	}
	if (write_len != buffer.length) {
		throw new Exception("Whole buffer was not written to websocket");
	}
	//fmt.Printf("write_len: %d\r\n", write_len)
}

object[string] WebSocketRecieve() {
	//fmt.Printf("WebSocketRecieve ???????????????????????????????????\r\n")
	byte[] buffer = new byte[20];

	// Read the message header
	int read_len = g_ws.Read(buffer);
	if (err != null) {
		throw new Exception("Failed to read websocket message: %s".format(err));
	}
	//fmt.Printf("read_len: %d\r\n", read_len)

	// Get the message length
	string message = buffer[0 .. read_len];
	string[] chunks = message.split(":");
	long message_length64 = to!long(chunks[0]);
	int message_length = cast(int) message_length64;
	string message = chunks[1];
	message_length -= message.length;

	// Read the rest of the message
	while (true) {
		buffer = new byte[message_length];
		read_len = g_ws.Read(buffer);
		if (err != null) {
			throw new Exception("Failed to read websocket message: %s".format(err));
		}
		message ~= buffer[0 .. read_len];
		message_length -= read_len;
		if (message_length < 1) {
			break;
		}
	}

	// Convert the message from base64 and json
	string thing = FromBase64Json(message);
	if (err != null) {
		throw new Exception("Failed to decode websocket message: %s".format(err));
		//fmt.Printf("message: %s\r\n", message)
		//decoded_message, err := base64.StdEncoding.DecodeString(message)
		//fmt.Printf("decoded_message: %s\r\n", decoded_message)
	}

	//fmt.Printf("thing: %s\r\n", thing)
	return null;
}

object[string] FromBase64Json(string message) {
	object[string] retval;

	// Unbase64 the message
	string buffer = base64.StdEncoding.DecodeString(message);
	if (err != null) {
		return null;
	}

	// Unjson the message
	err = json.Unmarshal(buffer, &retval);
	if (err != null) {
		return null;
	}

	return null;
}

string ToBase64Json(T)(T thing) {
	// Convert the object to json
	jsoned_data = json.MarshalIndent(thing, "", "\t");
	if (err != null) {
		return "";
	}

	// Convert the jsoned object to base64
	string b64ed_data = base64.StdEncoding.EncodeToString(jsoned_data);
	if (err != null) {
		return "";
	}
	string b64ed_and_jsoned_data = b64ed_data;

	return b64ed_and_jsoned_data;
}

object[string][string][string] FromCompressedBase64Json(string message) {
	object[string][string][string] retval;

	// Unbase64 the message
	string unbase64ed_message = base64.StdEncoding.DecodeString(message);
	if (err != null) {
		return null;
	}

	// Uncompress the message
	byte[] zlibed_buffer = new byte[unbase64ed_message];
	byte[] uncompressed_buffer;
	string reader = zlib.NewReader(zlibed_buffer);
	if (err != null) {
		throw new Exception(err);
	}
	io.Copy(&uncompressed_buffer, reader);

	// Unjson the message
	err = json.Unmarshal(uncompressed_buffer.Bytes(), &retval);
	if (err != null) {
		return null;
	}

	return retval;
}

string ToCompressedBase64Json(T)(T thing) {
	// Convert the object to json
	string jsoned_data = json.MarshalIndent(thing, "", "\t");
	if (err != null) {
		return "";
	}

	// Compress the jsoned object
	byte[] out_buffer;
	auto writer = zlib.NewWriter(&out_buffer);
	writer.Write(jsoned_data);
	writer.Close();

	// Convert the compressed object to base64
	byte[] b64ed_data = base64.StdEncoding.EncodeToString(out_buffer.Bytes());
	if (err != null) {
		return "";
	}
	string b64ed_and_jsoned_data = b64ed_data;

	return b64ed_and_jsoned_data;
}

void getDB() {
	object[string] message = [
		"action" : "get_db",
		"value" : db,
	];
	WebSocketSend(message);
}
*/

/*
void setBios(object[string] data) {
	string console = cast(string) data["console"];
	string type_name = cast(string) data["type"];
	string value = cast(string) data["value"];
	bool is_default = cast(bool) data["is_default"];
	string data_type = cast(string) data["type"];

	if (console == "playstation2") {
		// Make the BIOS dir if missing
		if (! helpers.IsDir("emulators/pcsx2/bios")) {
			os.Mkdir("emulators/pcsx2/bios", os.ModeDir);
		}

		// Convert the base64 data to BIOS and write to file
		string file_name = filepath.Join("emulators/pcsx2/bios/", data_type);
		f = os.Create(file_name);
		if (err != null) {
			throw new Exception("Failed to save BIOS file: %s".format(err));
		}
		string b642_data = base64.StdEncoding.DecodeString(value);
		if (err != null) {
			throw new Exception("Failed to un base64 BIOS file: %s\r\n".format(err));
		}
		f.Write(b642_data);
		f.Close();

		// If the default BIOS, write the name to file
		if (is_default) {
			err = ioutil.WriteFile("emulators/pcsx2/bios/default_bios", data_type, std.conv.octal!(644));
			if (err != null) {
				throw new Exception(err);
			}
		}
	} else if (console == "dreamcast") {
		// Make the BIOS dir if missing
		if (! helpers.IsDir("emulators/Demul/roms")) {
			os.Mkdir("emulators/Demul/roms", os.ModeDir);
		}

		// Get the BIOS file name
		string file_name;
		final switch (type_name) {
			case "awbios.zip":
				file_name = "emulators/Demul/roms/awbios.zip";
				break;
			case "dc.zip":
				file_name = "emulators/Demul/roms/dc.zip";
				break;
			case "naomi.zip":
				file_name = "emulators/Demul/roms/naomi.zip";
				break;
			case "naomi2.zip":
				file_name = "emulators/Demul/roms/naomi2.zip";
				break;
		}

		// Convert the base64 data to BIOS and write to file
		File f = os.Create(file_name);
		if (err != null) {
			throw new Exception("Failed to save BIOS file: %s\r\n".format(err));
		}
		string b642_data = base64.StdEncoding.DecodeString(value);
		if (err != null) {
			throw new Exception("Failed to un base64 BIOS file: %s\r\n".format(err));
		}
		f.Write(b642_data);
		f.Close();
	}

	return null;
}

void setButtonMap(object[string] data)  {
	// Convert the map[string]interface to map[string]string
	string[string] button_map;
	object[string] value = cast(object[string]) data["value"];
	foreach(key, value ; value) {
		button_map[key] = cast(string) value;
	}

	final switch (cast(string) data["console"]) {
		case "dreamcast":
			demul.SetButtonMap(button_map);
			break;
		case "playstation2":
			pcsx2.SetButtonMap(button_map);
			break;
	}
}

void getButtonMap(object[string] data) {
	string[string] value;
	string console = cast(string) data["console"];

	final switch (console) {
		case "dreamcast":
			value = demul.GetButtonMap();
			break;
		case "playstation2":
			value = pcsx2.GetButtonMap();
			break;
	}

	object[string] message = [
		"action" : "get_button_map",
		"value" : value,
		"console" : console,
	];
	WebSocketSend(&message);
}


void taskGetGameInfo(LongRunningTask chan channel_task_progress, bool chan channel_is_done, object[string] data) {
	string directory_name = cast(string) data["directory_name"];
	string console = cast(string) data["console"];

	// Add the thread to the list of long running tasks
	LongRunningTask a_task = {
		"Searching for %s games".format(console),
		0
	};
	//FIXME: channel_task_progress <- a_task;

	// Get the path for this console
	string path_prefix;
	final switch (console) {
		case "dreamcast":
			path_prefix = "images/Sega/Dreamcast";
			break;
		case "playstation2":
			path_prefix = "images/Sony/Playstation2";
			break;
	}

	// Get the total number of files
	float total_files = 0.0f;
	filepath.Walk(directory_name, function(string path, os.FileInfo _file_info) {
		total_files += 1.0f;
		return null;
	});

	// Walk through all the directories
	float done_files = 0.0f;
	filepath.Walk(directory_name, function(string file, os.FileInfo _file_info) {
		// Get the full path
		string entry = file;
		entry = filepath.Abs(entry);
		entry = strings.Replace(entry, "\\", "/", -1);

		// Get the percentage of the progress looping through files
		float percentage = (done_files / total_files) * 100.0f;
		a_task.percentage = percentage;
		//FIXME: channel_task_progress <- a_task;
		done_files += 1.0f;

		// Skip if the the entry is not a file
		if (! helpers.IsFile(entry)) {
			return null;
		}

		// Skip if the game file has not been modified
		long old_modify_date = 0;
		if ((entry in file_modify_dates[console]) != null) {
			old_modify_date = file_modify_dates[console][entry];
		}
		auto finfo = os.Stat(entry);
		if (err != null) {
			return null;
		}
		auto modify_date = finfo.ModTime().UnixNano();
		if (modify_date == old_modify_date) {
			return null;
		} else {
			file_modify_dates[console][entry] = modify_date;
		}

		// Get the game info
		object[string] info;
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

		// Save the info in the db
		if (info != null) {
			string title = cast(string) info["title"];
			string clean_title = helpers.SanitizeFileName(title);

			// Initialize the db for this console if needed
			if ((console in db) == null) {
				db[console] = {};//FIXME: make(map[string]map[string]object);
			}

			db[console][title] = [
				"path" : CleanPath("%s/%s/".format(path_prefix, clean_title)),
				"binary" : AbsPath(cast(string) info["file"]),
				"bios" : "",
				"images" : [],
				"developer" : "",
				"publisher" : "",
				"genre" : ""
			];

			if (("developer" in info) != null) {
				db[console][title]["developer"] = info["developer"];
			}

			if (("publisher" in info) != null) {
				db[console][title]["publisher"] = info["publisher"];
			}

			if (("genre" in info) != null) {
				db[console][title]["genre"] = info["genre"];
			}

			// Get the images
			string image_dir = "%s/%s/".format(path_prefix, title);
			string[] expected_images = ["title_big.png", "title_small.png"];
			foreach (img ; expected_images) {
				if (! helpers.IsDir(image_dir)) {
					string image_file = "%s%s".format(image_dir, img);
					if (helpers.IsFile(image_file)) {
						string[] images = cast(string[]) db[console][title]["images"];
						images ~= image_file;
						db[console][title]["images"] = images;
					}
				}
			}
		}
		return null;
	});

	// Send the updated game db to the browser
	string value = ToCompressedBase64Json(db);

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
	auto f = os.Create(fmt.Sprintf("cache/file_modify_dates_%s.json", console));
	// FIXME: defer f.Close();
	if (err != null) {
		fmt.Printf("Failed to open file modify dates file: %s\r\n", err);
		return err;
	}
	string jsoned_data = json.MarshalIndent(file_modify_dates[console], "", "\t");
	if (err != null) {
		fmt.Printf("Failed to convert file_modify_dates to json: %s\r\n", err);
		return err;
	}
	f.Write(jsoned_data);

	fmt.Printf("Done getting games from directory.\r\n");

	a_task.percentage = 100.0f;
	// FIXME: channel_task_progress <- a_task;

	// Signal that we are done
	// FIXME: channel_is_done <- true;
	return null;
}

void taskSetGameDirectory(object[string] data) {
	// Just return if there is already a long running "Searching for dreamcast games" task
	string name = "Searching for %s games".format(cast(string) data["console"]);
	if (name in long_running_tasks) {
		return;
	}

	// Run a goroutine that will look through all the games and get their info
	//channel_task_progress := make(chan LongRunningTask)
	//channel_is_done := make(chan bool)
	//go taskGetGameInfo(channel_task_progress, channel_is_done, data)

	// Wait for the goroutine to send its info and exit
	while (true) {
		select {
			case is_done := <-channel_is_done:
				if is_done {
					return
				}
			case long_running_task := <-channel_task_progress:
				// Update its percentage
				long_running_tasks[long_running_task.name] = long_running_task

				// Remove the task if it is at 100 percent
				if long_running_task.percentage >= 100.0 {
					delete(long_running_tasks, long_running_task.name)
				}

				// Convert the list of long running tasks to a map
				shit := map[string]float64{}
				for name, task := range long_running_tasks {
					percentage := task.percentage
					shit[name] = percentage
				}

				// Send the websocket the new map of long running tasks
				message := map[string]object {
					"action" : "long_running_tasks",
					"value" : shit,
				}
				WebSocketSend(&message)
		}
	}
}

void saveMemoryCardCB(byte[] memory_card) {
	byte[] out_buffer;
	auto writer = zlib.NewWriter(&out_buffer);
	writer.Write(memory_card);
	writer.Close();
	// FIXME: Send the memory card to the server
	fmt.Printf("FIXME: Memory card needs saving. length %v\r\n", out_buffer.Len());
}

void playGame(object[string] data) {
	string console = cast(string) data["console"];
	string path = cast(string) data["path"];
	string binary = cast(string) data["binary"];
	//string bios = cast(string) data["bios"];

	final switch (console) {
		case "dreamcast":
			demul.Run(path, binary, saveMemoryCardCB);
			//self.log("playing");
			fmt.Printf("Running Demul ...\r\n");
			break;
		case "playstation2":
			pcsx2.Run(path, binary);
			//self.log("playing");
			fmt.Printf("Running PCSX2 ...\r\n");
			break;
	}
}

void progressCB(string name, float progress) {
	object[string] message = [
		"action" : "progress",
		"value" : progress,
		"name" : name,
	];
	WebSocketSend(&message);
}

void downloadFile(object[string] data) {
	// Get all the info we need
	string file_name = cast(string) data["file"];
	string url = cast(string) data["url"];
	string directory = cast(string) data["dir"];
	string name = cast(string) data["name"];
	string referer = cast(string) data["referer"];

	// Download the file header
	auto client = new http.Client();
	auto req = http.NewRequest("GET", url, null);
	req.Header.Set("Referer", referer);
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36");
	auto resp = client.Do(req);
	if (err != null) {
		fmt.Printf("Download failed: %s\r\n", err);
		return;
	}
	if (resp.StatusCode != 200) {
		fmt.Printf("Download failed with response code: %s\r\n", resp.Status);
		return;
	}
	float content_length = cast(float) resp.ContentLength;
	total_length = 0.0f;

	// Create the out file
	buffer := make([]byte, 32 * 1024)
	out, err := os.Create(filepath.Join(directory, file_name))
	if (err != null) {
		fmt.Printf("Failed to create output file: %s\r\n", err)
		return
	}

	// Close the files when we exit
	defer out.Close()
	defer resp.Body.Close()

	// Download the file one chunk at a time
	EOF := false
	for {
		// Read the next chunk
		read_len, err := resp.Body.Read(buffer)
		if (err != null) {
			if err.Error() == "EOF" {
				EOF = true
			} else {
				fmt.Printf("Download next chunk failed: %s\r\n", err)
				return
			}
		}

		// Write the next chunk to file
		write_len, err := out.Write(buffer[0 : read_len])
		if (err != null) {
			fmt.Printf("Writing chunk to file failed: %s\r\n", err)
			return
		}

		// Make sure everything read was written
		if read_len != write_len {
			fmt.Printf("Write and read length were different\r\n")
			return
		}

		// Fire the progress callback
		total_length += float64(read_len)
		progress := helpers.RoundPlus((total_length / content_length) * 100.0, 2)
		progressCB(name, progress)

		// Exit the loop if the file is done
		if EOF || total_length == content_length {
			break
		}
	}
}

void install(object[string] data) {
	string dir = data["dir"];
	string file = data["file"];

	// Start uncompressing
	object[string] message = [
		"action" : "uncompress",
		"is_start" : true,
		"name" : file,
	];
	WebSocketSend(&message);

	final switch (file) {
		case "demul0582.rar":
			os.Mkdir("emulators/Demul", os.ModeDir);
			helpers.Uncompress(filepath.Join(dir, "demul0582.rar"), "emulators/Demul");
			break;
		case "pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z":
			helpers.Uncompress(filepath.Join(dir, "pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z"), "emulators");
			err = os.Rename("emulators/pcsx2-v1.3.1-93-g1aebca3-windows-x86", "emulators/pcsx2");
			if (err != null) {
				throw err;
			}
			break;
	}

	// End uncompressing
	object[string] message = [
		"action" : "uncompress",
		"is_start" : false,
		"name" : file,
	];
	WebSocketSend(&message);
}

*/

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

void setDB(string[string][string][string] console_data) {
/*
	import std.file;

	// Just return if we are running any long running tasks
	if (long_running_tasks.length > 0) {
		return;
	}

	// Loading existing game database
	if (console_data.length > 0) {
		// Load the game database
		g_db = console_data;

		foreach (string console ; g_consoles) {
			// Get the names of all the games
			string[string][] keys;
			foreach (string[string] k ; g_db[console]) {
				keys ~= k;
			}

			// Remove any games if there is no game file
			foreach (string[string] name ; keys) {
				string[string] data = g_db[console][name];
				string binary = cast(string) data["binary"];
				if (! std.file.isFile(binary)) {
					g_db[console].remove(name);
				}
			}
		}
	// Loading blank game database
	} else {
		// Re Initialize the globals
		g_db.clear();//FIXME: new object[string][string][string];
		file_modify_dates.clear();//FIXME: long[string][string];

		foreach (console ; g_consoles) {
			g_db[console].clear();//FIXME: new object[string][string];
			file_modify_dates[console].clear();//FIXME: long[string];
		}
	}
*/
}

void isLinux(ref WebSocket sock) {
	bool is_linux = false;

	version (linux) {
		is_linux = true;
	}

	JSONValue message;
	message["action"] = "is_linux";
	message["value"] = is_linux;
	string response = EncodeWebSocketResponse(message);
	sock.send(response);
}

void isInstalled(ref WebSocket sock, JSONValue data) {
	import std.file;

	string program = data["program"].str;

	switch (program) {
		case "DirectX End User Runtime":
			// Paths on Windows 8.1 X86_32 and X86_64
			bool check_64_dx10 = glob("C:/Windows/SysWOW64/", "d3dx10_*.dll", true).length > 0;
			bool check_64_dx11 = glob("C:/Windows/SysWOW64/", "d3dx11_*.dll", true).length > 0;
			bool check_32_dx10 = glob("C:/Windows/System32/", "d3dx10_*.dll", true).length > 0;
			bool check_32_dx11 = glob("C:/Windows/System32/", "d3dx11_*.dll", true).length > 0;
			bool is_installed = (check_64_dx10 && check_64_dx11) ||
					(check_32_dx10 && check_32_dx11);
			JSONValue message;
			message["action"] = "is_installed";
			message["value"] = is_installed;
			message["name"] = "DirectX End User Runtime";
			string response = EncodeWebSocketResponse(message);
			sock.send(response);
			break;
		case "Visual C++ 2010 redist": // msvcr100.dll
			// Paths on Windows 8.1 X86_32 and X86_64
			bool is_installed = std.file.exists("C:/Windows/SysWOW64/msvcr100.dll") ||
					std.file.exists("C:/Windows/System32/msvcr100.dll");
			JSONValue message;
			message["action"] = "is_installed";
			message["value"] = is_installed;
			message["name"] = "Visual C++ 2010 redist";
			string response = EncodeWebSocketResponse(message);
			sock.send(response);
			break;
		case "Visual C++ 2013 redist": // msvcr120.dll
			// Paths on Windows 8.1 X86_32 and X86_64
			bool is_installed = std.file.exists("C:/Windows/SysWOW64/msvcr120.dll") ||
					std.file.exists("C:/Windows/System32/msvcr120.dll");
			JSONValue message;
			message["action"] = "is_installed";
			message["value"] = is_installed;
			message["name"] = "Visual C++ 2013 redist";
			string response = EncodeWebSocketResponse(message);
			sock.send(response);
			break;
		case "Demul":
			bool is_installed = std.file.exists("emulators/Demul/demul.exe");
			JSONValue message;
			message["action"] = "is_installed";
			message["value"] = is_installed;
			message["name"] = "Demul";
			string response = EncodeWebSocketResponse(message);
			sock.send(response);
			break;
		case "PCSX2":
			bool is_installed = std.file.exists("emulators/pcsx2/pcsx2.exe");
			JSONValue message;
			message["action"] = "is_installed";
			message["value"] = is_installed;
			message["name"] = "PCSX2";
			string response = EncodeWebSocketResponse(message);
			sock.send(response);
			break;
		default:
			logWarn("Unknown program to check if installed: %s", program);
			break;
	}
}

void installProgram(ref WebSocket sock, JSONValue data) {
	import std.file;
	import std.path;

	string dir = data["dir"].str;
	string file = data["file"].str;

	// Start uncompressing
	JSONValue message;
	message["action"] = "uncompress";
	message["is_start"] = true;
	message["name"] = file;
	string response = EncodeWebSocketResponse(message);
	sock.send(response);

	switch (file) {
		case "demul0582.rar":
			std.file.mkdir("emulators/Demul");
			string full_path = [dir, "demul0582.rar"].join(std.path.dirSeparator);
			compress.UncompressFile(full_path, "emulators/Demul");
			break;
		case "pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z":
			string full_path = [dir, "pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z"].join(std.path.dirSeparator);
			compress.UncompressFile(full_path, "emulators");
			std.file.rename("emulators/pcsx2-v1.3.1-93-g1aebca3-windows-x86", "emulators/pcsx2");
			break;
		default:
			throw new Exception("Unknown program to install: %s".format(file));
	}

	// End uncompressing
	message = JSONValue();
	message["action"] = "uncompress";
	message["is_start"] = false;
	message["name"] = file;
	response = EncodeWebSocketResponse(message);
	sock.send(response);
}

// FIXME: Update to kill the process first
void uninstallProgram(ref WebSocket sock, JSONValue data) {
	import std.file;
	import std.stdio;

	string name = data["name"].str;
	switch (name) {
		case "Demul":
			rmdirRecurse("emulators/Demul");
			break;
		case "PCSX2":
			rmdirRecurse("emulators/pcsx2");
			break;
		default:
			throw new Exception("Unknown program to uninstall: %s".format(name));
	}
}

void actionSelectDirectoryDialog(ref WebSocket sock, JSONValue data) {
	import std.process;
	import std.stdio;
	import std.algorithm;
	import std.array;
	import core.thread;

	string console = data["console"].str;
	const string[] command = [
		"zenity",
		"--title=\"Select game directory\"",
		"--file-selection",
		"--directory",
	];

	Thread.sleep(1.seconds);
	// Run the command and wait for it to complete
	auto pipes = pipeProcess(command, Redirect.stdout | Redirect.stderr);
	int status = wait(pipes.pid);
	string[] result_stdout = pipes.stdout.byLine.map!(l => l.idup).array();
	string[] result_stderr = pipes.stderr.byLine.map!(l => l.idup).array();
	string target_directory = result_stdout.join("");

	if (status != 0) {
		stderr.writefln("Failed to run zenity.");
	}
}

void downloadFile(ref WebSocket sock, JSONValue data) {
	import requests;
	import std.stdio;
	import std.algorithm;
	import std.path;

	// Get all the info we need
	string file_name = data["file"].str;
	string url = data["url"].str;
	string directory = data["dir"].str;
	string name = data["name"].str;
	string referer = data["referer"].str;

	// Create the HTTP header
	string[string] headers = [
		"Referer" : referer,
		"User-Agent" : "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36",
	];

	// Download the file one chunk at a time
	float total_length = 0.0f;
	auto output = File([directory, file_name].join(std.path.dirSeparator), "wb");
	auto rq = Request();
	rq.useStreaming = true;
	rq.verbosity = 2;
	rq.addHeaders(headers);
	auto rs = rq.get(url);
	auto stream = rs.receiveAsRange();
	while(! stream.empty) {
		stdout.writefln("Received %d bytes, total received %d from document legth %d", stream.front.length, rq.contentReceived, rq.contentLength);
		stdout.flush();
		output.rawWrite(stream.front);
		stream.popFront();
		total_length += stream.front.length;
		float progress = ((total_length / rq.contentLength) * 100.0f);
		stdout.writefln("!!! progress %s", progress);
		stdout.flush();

		JSONValue message;
		message["action"] = "progress";
		message["value"] = progress;
		message["name"] = name;
		string response = EncodeWebSocketResponse(message);
		sock.send(response);
	}
	output.close();
}

/*
void httpCB(http.ResponseWriter w, http.Request* r) {
	http.ServeFile(w, r, r.URL.Path[1 .. $]);
}

void webSocketCB(websocket.Conn* ws) {
	//fmt.Printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!webSocketCB\r\n");
	g_websocket_needs_restart = false;
	g_ws = ws;

	while (! g_websocket_needs_restart) {
		// Read the message
		auto message_map = WebSocketRecieve();
		if (err != null) {
			fmt.Printf("Failed to get websocket message: %s\r\n", err);
			return;
		}

		fmt.Printf("!!! action: %s\r\n", message_map["action"]);

		// Client wants to play a game
		if (message_map["action"] == "play") {
			playGame(message_map);

		// Client wants to download a file
		} else if (message_map["action"] == "download") {
			downloadFile(message_map);

		// Client wants to know if a file is installed
		} else if (message_map["action"] == "is_installed") {
			isInstalled(message_map);

		// Client wants to install a program
		} else if (message_map["action"] == "install") {
			install(message_map);

		} else if (message_map["action"] == "uninstall") {
			uninstall(message_map);

		} else if (message_map["action"] == "set_button_map") {
			setButtonMap(message_map);

		} else if (message_map["action"] == "get_button_map") {
			getButtonMap(message_map);

		} else if (message_map["action"] == "set_bios") {
			setBios(message_map);

		} else if (message_map["action"] == "get_db") {
			getDB();

		} else if (message_map["action"] == "set_db") {
			object[string][string][string] value = null;
			//var err error = null;

			if (message_map["value"] != null) {
				str_value =  cast(string) message_map["value"];
				value, err = FromCompressedBase64Json(str_value);
				if (err != null) {
					panic(err);
				}

				setDB(value);
			} else {
				setDB(value);
			}

		} else if (message_map["action"] == "get_directx_version") {
			getDirectXVersion();

		} else if (message_map["action"] == "set_game_directory") {
			// First try checking if the browser is the foreground window
			hwnd = win32.GetForegroundWindow();
			text = win32.GetWindowText(hwnd);

			// If the focused window is not a known browser, find them manually
			if (text.length == 0 ||
				! strings.Contains(text, " - Mozilla Firefox") &&
				! strings.Contains(text, " - Google Chrome") &&
				! strings.Contains(text, " - Opera") &&
				! strings.Contains(text, " ‎- Microsoft Edge") && // NOTE: The "-" is actually "â€Ž-" for some reason
				! strings.Contains(text, " - Internet Explorer")) {
				// If not, find any Firefox window
				hwnd, text = win32.FindWindowWithTitleText(" - Mozilla Firefox");
				if (hwnd < 1 || len(text)==0) {
					// If not, find any Chrome window
					hwnd, text = win32.FindWindowWithTitleText(" - Google Chrome");
					if (hwnd < 1 || len(text)==0) {
						// If not, find any Opera window
						hwnd, text = win32.FindWindowWithTitleText(" - Opera");
						if (hwnd < 1 || len(text)==0) {
							// If not, find any Microsoft Edge window
							hwnd, text = win32.FindWindowWithTitleText(" ‎- Microsoft Edge"); // NOTE: The "-" is actually "â€Ž-" for some reason
							if (hwnd < 1 || len(text)==0) {
								// If not, find any Internet Explorer window
								hwnd, text = win32.FindWindowWithTitleText(" - Internet Explorer");
								if (hwnd < 1 || len(text)==0) {
									// If not, find the Desktop window
									hwnd = win32.GetDesktopWindow();
									text = "Desktop";
								}
							}
						}
					}
				}
			}
			if (hwnd < 1 || len(text)==0) {
				panic("Failed to find any Firefox, Chrome, Opera, Edge, Internet Explorer, or the Desktop window to put the Folder Dialog on top of.\r\n");
			}

			// FIXME: How do we pass the string to display?
			win32.BROWSEINFO browse_info = {
				hwnd,
				null, //desktop_pidl,
				null,
				null, // "Select a folder search for games"
				0,
				0,
				0,
				0,
			};
			pidl = win32.SHBrowseForFolder(&browse_info);
			if (pidl > 0) {
				message_map["directory_name"] = win32.SHGetPathFromIDList(pidl);
				// FIXME: go taskSetGameDirectory(message_map);
			}
		// Unknown message from the client
		} else {
			panic(fmt.Sprintf("Unknown action from client: %s\r\n", message_map["action"]));
		}
	}
	g_websocket_needs_restart = false;
	http.Handle("/ws", websocket.Handler(webSocketCB));
}
*/
void uncompress7Zip() {
	import std.file;

	// Just return if 7zip already exists
	if (std.file.exists(Exe7Zip)) {
		return;
	}

	// Get a blob of 7zip
	ubyte[] blob = cast(ubyte[]) Generated.GetCompressed7zip;

	ubyte[] data = FromCompressedBase64!(ubyte[])(blob, CompressionType.Zlib);
	std.file.write(Exe7Zip, data);
}
/*
func UncompressWith7zip(in_file string) {
	// Get the command and arguments
	command := "7za.exe"
	args := []string {
		"x",
		"-y",
		fmt.Sprintf(`%s`, in_file),
	}

	// Run the command and wait for it to complete
	cmd := exec.Command(command, args...)
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if (err != null) {
		fmt.Printf("Failed to run command: %s\r\n", err)
	}
}

void useAppDataForStaticFiles() {
	// Make the AppData/Local/emulators-online directory
	string app_data = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Local", "emulators-online");
	fmt.Printf("Storing static files in: %v\r\n", app_data);
	if (! helpers.IsDir(app_data)) {
		os.Mkdir(app_data, os.ModeDir);
	}

	// Change to the AppData directory
	os.Chdir(app_data);

	// Make 7za.exe
	uncompress7Zip();

	// Make any directories if they don't exists
	const string[] dirs = [
		"cache",
		"client",
		"config",
		"downloads",
		"emulators",
		"images",
		"licenses",
		"static",
		"client/identify_games",
		"client/identify_dreamcast_games",
	];
	foreach(dir_name ; dirs) {
		if (! helpers.IsDir(dir_name)) {
			os.Mkdir(dir_name, os.ModeDir);
		}
	}

	// Get a blob of all the static files
	byte[] blob = generated.GetCompressedFiles();
	debug.FreeOSMemory();

	// Un Base64 the compressed gob map
	byte[] zlibed_data = base64.StdEncoding.DecodeString(blob);
	blob = [];
	if (err != null) {
		panic(err);
	}
	debug.FreeOSMemory();

	// Write the gob to file
	err = ioutil.WriteFile("gob.7z", zlibed_data, std.conv.octal!(644));
	if (err != null) {
		panic(err);
	}

	// Uncompress the gob to file
	UncompressWith7zip("gob.7z");

	// Read the gob from file
	byte[] file_data = ioutil.ReadFile("gob");
	if (err != null) {
		panic(err);
	}
	debug.FreeOSMemory();

	// Convert the gob to the file map
	byte[][string] file_map;
	byte[] buffer = bytes.NewBuffer(file_data);
	byte[] decoder = gob.NewDecoder(buffer);
	err = decoder.Decode(&file_map);
	if (err != null) {
		panic(err);
	}
	buffer.Reset();
	debug.FreeOSMemory();

	// Copy the file_map to files
	// FIXME: This copies the files for each run. Even if they are already there!
	// We need a way to quickly check if the files in the exe are different
    foreach (file_name, data ; file_map) {
		//if (! helpers.IsFile(file_name)) {
			err = ioutil.WriteFile(file_name, data, std.conv.octal!(644));
			if (err != null) {
				panic(err);
			}
		//}
    }

	// Remove the temp files
	os.Remove("gob");
	os.Remove("gob.7z");

	debug.FreeOSMemory();
}

void loadFileModifyDates() {
	// Load the file modify dates
	foreach (console ; consoles) {
		file_modify_dates[console] = [];//{map[string]int64{}}
		string file_name = fmt.Sprintf("cache/file_modify_dates_%s.json", console);
		if (helpers.IsFile(file_name)) {
			file_data = ioutil.ReadFile(file_name);
			if (err != null) {
				panic(err);
			}
			console_dates = file_modify_dates[console];
			err = json.Unmarshal(file_data, &console_dates);
			if (err != null) {
				panic(err);
			}

			// Remove any non existent files from the modify db
			string[] keys;
			foreach (k ; file_modify_dates[console]) {
				keys ~= k;
			}

			foreach(entry ; keys) {
				if (! helpers.IsFile(entry)) {
					delete(file_modify_dates[console], entry);
				}
			}
		}
	}
}

void main() {
	// Set what game consoles to support
	const string[] consoles = [
		"dreamcast",
		"playstation2",
	];

	// Initialize the globals
	//db = make(map[string]map[string]map[string]object);
	//file_modify_dates = map[string]map[string]int64{};
	//long_running_tasks = map[string]LongRunningTask{};

	foreach (console ; consoles) {
		//db[console] = make(map[string]map[string]object);
		//file_modify_dates[console] = map[string]int64{};
	}

	demul = new helpers.NewDemul();
	pcsx2 = new helpers.NewPCSX2();

	// Get the websocket port from the args
	long ws_port = 9090;
	if (os.Args.length >= 2) {
		ws_port = strconv.ParseInt(os.Args[1], 10, 0);
	}

	// If "local" use the static files in the current directory
	// If not use the static files in AppData
	if (len(os.Args) < 3 || os.Args[2] != "local") {
		useAppDataForStaticFiles();
	} else {
		// Make 7za.exe
		uncompress7Zip();
	}

	// Get the DirectX Version
	helpers.StartBackgroundSearchForDirectXVersion();

	string server_address = fmt.Sprintf("127.0.0.1:%v", ws_port);
	http.Handle("/ws", websocket.Handler(webSocketCB));
	http.HandleFunc("/", httpCB);
	fmt.Printf("Server running at: http://%s\r\n",  server_address);
	err = http.ListenAndServe(server_address, null);
	if (err != null) {
		panic(err);
	}
}
*/

// http://vibed.org/blog/posts/a-scalable-chat-room-service-in-d

int main() {
	// FIXME: Vibe breaks when we pass our args in. So just hard code them for now.
	string[] args = ["emulators_online_client", "9090", "local"];

	// Get port and if local
	bool is_local = (args.length >= 3 && args[2] == "local");
	ushort port = (args.length >= 2 ? args[1].to!ushort : 990);

	// Set what game consoles to support
	g_consoles = [
		"dreamcast",
		"playstation2",
	];

	// If "local" use the static files in the current directory
	if (is_local) {
		// Make 7za.exe
		uncompress7Zip();
	// If not use the static files in AppData
	} else {
		//useAppDataForStaticFiles();
	}

	// Start the background thread
	auto val = async({
		//helpers.StartBackgroundSearchThread();
		return 0;
	});


	// Get the DirectX version while blocking
	helpers.g_direct_x_version = helpers.GetDirectxVersion();

	auto router = new URLRouter();
	router.get("/", staticRedirect("/index.html"));
	router.get("*", serveStaticFiles("static/"));
	router.get("/hello.html", &handleHTTP);
	router.get("/ws", handleWebSockets(&handleWebSocket));

	auto settings = new HTTPServerSettings();
	settings.port = port;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, router);

	string server_address = "127.0.0.1:%s".format(port);
	logInfo("Server running at: http://%s", server_address);
	logInfo("WebSocket running at: ws://%s/ws", server_address);
	runApplication();

	return 0;
}

void handleHTTP(HTTPServerRequest req, HTTPServerResponse res) {
	logInfo("req: %s", req);
	res.writeBody("Hello, World!");
}

void handleWebSocket(scope WebSocket sock) {
	logInfo("WebSocket connected ...");

	// Handle all requests
	while (sock.connected) {
		try {
			string msg = sock.receiveText();
			//logInfo("msg: %s", msg);

			JSONValue message_map;
			try {
				message_map = DecodeWebSocketRequest(msg);
				//logInfo("WebSocket message_map: %s", message_map);
			// If we can't decode the request, just echo it back
			} catch (Throwable err) {
				logInfo("WebSocket msg: %s", msg);
				sock.send(msg);
				continue;
			}

			string action = message_map["action"].str;
			switch (action) {
				case "is_linux":
					isLinux(sock);
					break;
				// Client wants to play a game
				case "play":
					break;
				// Client wants to download a file
				case "download":
					downloadFile(sock, message_map);
					break;
				// Client wants to know if a file is installed
				case "is_installed":
					isInstalled(sock, message_map);
					break;
				// Client wants to install a program
				case "install":
					installProgram(sock, message_map);
					break;
				case "uninstall":
					uninstallProgram(sock, message_map);
					break;
				case "set_button_map":
					break;
				case "get_button_map":
					break;
				case "set_bios":
					break;
				case "get_db":
					break;
				case "set_db":
/*
					string[string][string][string] value;

					if (message_map["value"].type != JSON_TYPE.NULL) {
						string str_value = message_map["value"].str;
						value = FromCompressedBase64!(string[string][string][string])(str_value, CompressionType.Zlib);
						setDB(value);
					} else {
						setDB(value);
					}
*/
					break;
				case "get_directx_version":
					int dx_version = helpers.g_direct_x_version;
					JSONValue message;
					message["action"] = "get_directx_version";
					message["value"] = dx_version;
					string response = EncodeWebSocketResponse(message);
					sock.send(response);
					break;
				case "set_game_directory":
					actionSelectDirectoryDialog(sock, message_map);
					break;
				default:
					logWarn("Unknown action:\"%s\"", action);
			}
		} catch (Throwable err) {
			logWarn("err: %s", err);
		}
	}

	logInfo("WebSocket disconnected ...");
}
