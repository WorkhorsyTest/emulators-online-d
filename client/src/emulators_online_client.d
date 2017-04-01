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

void actionIsLinux(ref WebSocket sock) {
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

void actionIsInstalled(ref WebSocket sock, ref JSONValue data) {
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

void actionInstallProgram(ref WebSocket sock, ref JSONValue data) {
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
void actionUninstallProgram(ref WebSocket sock, ref JSONValue data) {
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

void actionSelectDirectoryDialog(ref WebSocket sock, ref JSONValue data) {
	import gui;

	string console = data["console"].str;
	string dir_name = gui.DialogDirectorySelect();

	if (dir_name != null) {
		JSONValue message;
		message["action"] = "set_game_directory";
		message["console"] = console;
		message["directory_name"] = dir_name;
		string response = EncodeWebSocketResponse(message);
		sock.send(response);
		// FIXME: go taskSetGameDirectory(message_map);
	}
}

void actionDownloadFile(ref WebSocket sock, ref JSONValue data) {
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

version (Windows) {
	import win32.windef;
	import win32.winuser;
	import win32_helpers;

	extern (Windows) int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow) {
		return runWinMain(&actualMain);
	}
}
version (linux) {
	int main() {
		return actualMain();
	}
}


int actualMain() {
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
					actionIsLinux(sock);
					break;
				// Client wants to play a game
				case "play":
					break;
				// Client wants to download a file
				case "download":
					actionDownloadFile(sock, message_map);
					break;
				// Client wants to know if a file is installed
				case "is_installed":
					actionIsInstalled(sock, message_map);
					break;
				// Client wants to install a program
				case "install":
					actionInstallProgram(sock, message_map);
					break;
				case "uninstall":
					actionUninstallProgram(sock, message_map);
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
