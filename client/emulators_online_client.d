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
import core.thread;
import WebSocket;


bool g_websocket_needs_restart;

class LongRunningTask {
	string name;
	float percentage;
}

// db is accessed like db[console][game][binary_name]
map[string]map[string]map[string]object db;
map[string]map[string]int64 file_modify_dates;
map[string]LongRunningTask long_running_tasks;
helpers.Demul demul;
helpers.PCSX2 pcsx2;

string[] consoles;

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
	err = json.Unmarshal(buffer, &retval)
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

map[string]map[string]map[string]object FromCompressedBase64Json(string message) {
	map[string]map[string]map[string]object retval;

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
	object[string] message = {
		"action" : "get_db",
		"value" : db,
	};
	WebSocketSend(message);
}

void setDB(map[string]map[string]map[string]object console_data) {
	// Just return if we are running any long running tasks
	if (long_running_tasks.length > 0) {
		return;
	}

	// Loading existing game database
	if (console_data != null) {
		// Load the game database
		db = console_data;

		foreach (console ; consoles) {
			// Get the names of all the games
			string[] keys;
			foreach (k ; db[console]) {
				keys ~= k;
			}

			// Remove any games if there is no game file
			foreach (name ; keys) {
				auto data = db[console][name];
				auto binary = cast(string) data["binary"];
				if (! helpers.IsFile(binary)) {
					delete(db[console], name);
				}
			}
		}
	// Loading blank game database
	} else {
		// Re Initialize the globals
		db = new map[string]map[string]map[string]object;
		file_modify_dates = map[string]map[string]long;

		foreach (console ; consoles) {
			db[console] = new map[string]map[string]object;
			file_modify_dates[console] = map[string]long;
		}
	}
}

void getDirectXVersion() {
	object[string] message = {
		"action" : "get_directx_version",
		"value" : helpers.GetDirectXVersion(),
	};
	WebSocketSend(message);
}

void setBios(map[string]object data) {
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
		f, err := os.Create(file_name);
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
			err = ioutil.WriteFile("emulators/pcsx2/bios/default_bios", []byte(data_type), 0644);
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

func getButtonMap(data map[string]object) {
	var value map[string]string
	console := data["console"].(string)

	final switch console {
		case "dreamcast":
			value = demul.GetButtonMap()
			break;
		case "playstation2":
			value = pcsx2.GetButtonMap()
			break;
	}

	message := map[string]object {
		"action" : "get_button_map",
		"value" : value,
		"console" : console,
	}
	WebSocketSend(&message)
}


func taskGetGameInfo(channel_task_progress chan LongRunningTask, channel_is_done chan bool, data map[string]object) error {
	directory_name := data["directory_name"].(string)
	console := data["console"].(string)

	// Add the thread to the list of long running tasks
	a_task := LongRunningTask {
		fmt.Sprintf("Searching for %s games", console),
		0,
	}
	channel_task_progress <- a_task

	// Get the path for this console
	var path_prefix string
	final switch console {
		case "dreamcast":
			path_prefix = "images/Sega/Dreamcast"
			break;
		case "playstation2":
			path_prefix = "images/Sony/Playstation2"
			break;
	}

	// Get the total number of files
	total_files := 0.0
	filepath.Walk(directory_name, func(path string, _ os.FileInfo, _ error) error {
		total_files += 1.0
		return null
	})

	// Walk through all the directories
	done_files := 0.0
	filepath.Walk(directory_name, func(file string, _ os.FileInfo, _ error) error {
		// Get the full path
		entry := file
		entry, _ = filepath.Abs(entry)
		entry = strings.Replace(entry, "\\", "/", -1)

		// Get the percentage of the progress looping through files
		percentage := (done_files / total_files) * 100.0
		a_task.percentage = percentage
		channel_task_progress <- a_task
		done_files += 1.0

		// Skip if the the entry is not a file
		if ! helpers.IsFile(entry) {
			return null
		}

		// Skip if the game file has not been modified
		var old_modify_date int64 = 0
		if val, ok := file_modify_dates[console][entry]; ok {
			old_modify_date = val
		}
		finfo, err := os.Stat(entry)
		if (err != null) {
			return null
		}
		modify_date := finfo.ModTime().UnixNano()
		if modify_date == old_modify_date {
			return null
		} else {
			file_modify_dates[console][entry] = modify_date
		}

		// Get the game info
		var info map[string]object
		var cmd *exec.Cmd
		if console == "dreamcast" {
			cmd = exec.Command("client/identify_games/identify_games.exe", console, entry)
		} else if console == "playstation2" {
			cmd = exec.Command("client/identify_games/identify_games.exe", console, entry)
		} else {
			panic(fmt.Sprintf("Unexpected console: %s", console))
		}

		// Run the command and get the info for this game
		var out bytes.Buffer
		cmd.Stdout = &out
		err = cmd.Run()
		if (err != null) {
			fmt.Printf("Failed to get game info for file: %s\r\n", entry)
			return null
		}
		out_bytes := out.Bytes()
		if len(out_bytes) > 0 {
			err := json.Unmarshal(out_bytes, &info)
			if (err != null) {
				fmt.Printf("Failed to convert json to map: %s\r\n%s\r\n", err, string(out_bytes))
				return null
			}
		} else {
			return null
		}
		if (err != null) {
			fmt.Printf("Failed to find info for game \"%s\"\r\n%s\r\n", entry, err)
			return null
		}
		fmt.Printf("getting game info: %s\r\n", info["title"].(string))
		info["file"] = entry

		// Save the info in the db
		if info != null {
			title := info["title"].(string)
			clean_title := helpers.SanitizeFileName(title)

			// Initialize the db for this console if needed
			if _, ok := db[console]; !ok {
				db[console] = make(map[string]map[string]object)
			}

			db[console][title] = map[string]object {
				"path" : CleanPath(fmt.Sprintf("%s/%s/", path_prefix, clean_title)),
				"binary" : AbsPath(info["file"].(string)),
				"bios" : "",
				"images" : []string{},
				"developer" : "",
				"publisher" : "",
				"genre" : "",
			}

			if val, ok := info["developer"]; ok {
				db[console][title]["developer"] = val
			}

			if val, ok := info["publisher"]; ok {
				db[console][title]["publisher"] = val
			}

			if val, ok := info["genre"]; ok {
				db[console][title]["genre"] = val
			}

			// Get the images
			image_dir := fmt.Sprintf("%s/%s/", path_prefix, title)
			expected_images := []string{"title_big.png", "title_small.png"}
			for _, img := range expected_images {
				if ! helpers.IsDir(image_dir) {
					image_file := fmt.Sprintf("%s%s", image_dir, img)
					if helpers.IsFile(image_file) {
						images := db[console][title]["images"].([]string)
						images = append(images, image_file)
						db[console][title]["images"] = images
					}
				}
			}
		}
		return null
	})

	// Send the updated game db to the browser
	value, err := ToCompressedBase64Json(db)
	if (err != null) {
		panic(err)
	}

	message := map[string]object {
		"action" : "set_db",
		"value" : value,
	}
	WebSocketSend(&message)
/*
	// Write the db cache file
	f, err := os.Create(fmt.Sprintf("cache/game_db_%s.json", console))
	defer f.Close()
	if (err != null) {
		fmt.Printf("Failed to open cache file: %s\r\n", err)
		return err
	}
	jsoned_data, err := json.MarshalIndent(db[console], "", "\t")
	if (err != null) {
		fmt.Printf("Failed to convert db to json: %s\r\n", err)
		return err
	}
	f.Write(jsoned_data)
*/

	// Write the modify dates cache file
	f, err := os.Create(fmt.Sprintf("cache/file_modify_dates_%s.json", console))
	defer f.Close()
	if (err != null) {
		fmt.Printf("Failed to open file modify dates file: %s\r\n", err)
		return err
	}
	jsoned_data, err := json.MarshalIndent(file_modify_dates[console], "", "\t")
	if (err != null) {
		fmt.Printf("Failed to convert file_modify_dates to json: %s\r\n", err)
		return err
	}
	f.Write(jsoned_data)

	fmt.Printf("Done getting games from directory.\r\n")

	a_task.percentage = 100.0
	channel_task_progress <- a_task

	// Signal that we are done
	channel_is_done <- true
	return null
}

func taskSetGameDirectory(data map[string]object) {
	// Just return if there is already a long running "Searching for dreamcast games" task
	name := fmt.Sprintf("Searching for %s games", data["console"].(string))
	if _, ok := long_running_tasks[name]; ok {
		return
	}

	// Run a goroutine that will look through all the games and get their info
	channel_task_progress := make(chan LongRunningTask)
	channel_is_done := make(chan bool)
	go taskGetGameInfo(channel_task_progress, channel_is_done, data)

	// Wait for the goroutine to send its info and exit
	for {
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

func saveMemoryCardCB(memory_card []byte) {
	var out_buffer bytes.Buffer
	writer := zlib.NewWriter(&out_buffer)
	writer.Write([]byte(memory_card))
	writer.Close()
	// FIXME: Send the memory card to the server
	fmt.Printf("FIXME: Memory card needs saving. length %v\r\n", out_buffer.Len())
}

func playGame(data map[string]object) {
	console := data["console"].(string)
	path := data["path"].(string)
	binary := data["binary"].(string)
	//bios := data["bios"].(string)

	final switch console {
		case "dreamcast":
			demul.Run(path, binary, saveMemoryCardCB)
			//self.log("playing")
			fmt.Printf("Running Demul ...\r\n")
			break;
		case "playstation2":
			pcsx2.Run(path, binary)
			//self.log("playing")
			fmt.Printf("Running PCSX2 ...\r\n")
			break;
	}
}

func progressCB(name string, progress float64) {
	message := map[string]object {
		"action" : "progress",
		"value" : progress,
		"name" : name,
	}
	WebSocketSend(&message)
}

func downloadFile(data map[string]object) {
	// Get all the info we need
	file_name := data["file"].(string)
	url := data["url"].(string)
	directory := data["dir"].(string)
	name := data["name"].(string)
	referer := data["referer"].(string)

	// Download the file header
	client := &http.Client{}
	req, _ := http.NewRequest("GET", url, null)
	req.Header.Set("Referer", referer)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36")
	resp, err := client.Do(req)
	if (err != null) {
		fmt.Printf("Download failed: %s\r\n", err)
		return
	}
	if resp.StatusCode != 200 {
		fmt.Printf("Download failed with response code: %s\r\n", resp.Status)
		return
	}
	content_length := float64(resp.ContentLength)
	total_length := 0.0

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

func install(data map[string]object) {
	dir := data["dir"].(string)
	file := data["file"].(string)

	// Start uncompressing
	message := map[string]object{
		"action" : "uncompress",
		"is_start" : true,
		"name" : file,
	}
	WebSocketSend(&message)

	final switch file {
		case "demul0582.rar":
			os.Mkdir("emulators/Demul", os.ModeDir)
			helpers.Uncompress(filepath.Join(dir, "demul0582.rar"), "emulators/Demul")
			break;
		case "pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z":
			helpers.Uncompress(filepath.Join(dir, "pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z"), "emulators")
			err := os.Rename("emulators/pcsx2-v1.3.1-93-g1aebca3-windows-x86", "emulators/pcsx2")
			if (err != null) {
				panic(err)
			}
			break;
	}

	// End uncompressing
	message = map[string]object{
		"action" : "uncompress",
		"is_start" : false,
		"name" : file,
	}
	WebSocketSend(&message)
}

// FIXME: Update to kill the process first
func uninstall(data map[string]object) {
	final switch data["program"].(string) {
		case "Demul":
			os.RemoveAll("emulators/Demul")
			break;
		case "PCSX2":
			os.RemoveAll("emulators/pcsx2")
			break;
	}
}

func isInstalled(data map[string]object) {
	program := data["program"].(string)

	final switch program {
	case "DirectX End User Runtime":
		// Paths on Windows 8.1 X86_32 and X86_64
		check_64_dx10, _ := filepath.Glob("C:/Windows/SysWOW64/d3dx10_*.dll")
		check_64_dx11, _ := filepath.Glob("C:/Windows/SysWOW64/d3dx11_*.dll")
		check_32_dx10, _ := filepath.Glob("C:/Windows/System32/d3dx10_*.dll")
		check_32_dx11, _ := filepath.Glob("C:/Windows/System32/d3dx11_*.dll")
		exist := (len(check_64_dx10) > 0 && len(check_64_dx11) > 0) ||
				(len(check_32_dx10) > 0 && len(check_32_dx11) > 0)
		message := map[string]object {
			"action" : "is_installed",
			"value" : exist,
			"name" : "DirectX End User Runtime",
		}
		WebSocketSend(&message)
		break;
	case "Visual C++ 2010 redist": // msvcr100.dll
		// Paths on Windows 8.1 X86_32 and X86_64
		exist := helpers.PathExists("C:/Windows/SysWOW64/msvcr100.dll") ||
				helpers.PathExists("C:/Windows/System32/msvcr100.dll")
		message := map[string]object {
			"action" : "is_installed",
			"value" : exist,
			"name" : "Visual C++ 2010 redist",
		}
		WebSocketSend(&message)
		break;
	case "Visual C++ 2013 redist": // msvcr120.dll
		// Paths on Windows 8.1 X86_32 and X86_64
		exist := helpers.PathExists("C:/Windows/SysWOW64/msvcr120.dll") ||
				helpers.PathExists("C:/Windows/System32/msvcr120.dll")
		message := map[string]object {
			"action" : "is_installed",
			"value" : exist,
			"name" : "Visual C++ 2013 redist",
		}
		WebSocketSend(&message)
		break;
	case "Demul":
		exist := helpers.PathExists("emulators/Demul/demul.exe")
		message := map[string]object {
			"action" : "is_installed",
			"value" : exist,
			"name" : "Demul",
		}
		WebSocketSend(&message)
		break;
	case "PCSX2":
		exist := helpers.PathExists("emulators/pcsx2/pcsx2.exe")
		message := map[string]object {
			"action" : "is_installed",
			"value" : exist,
			"name" : "PCSX2",
		}
		WebSocketSend(&message)
		break;
	default:
		fmt.Printf("Unknown program to check if installed: %s\r\n", program)
		break;
	}
}

func httpCB(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, r.URL.Path[1:])
}

func webSocketCB(ws *websocket.Conn) {
	//fmt.Printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!webSocketCB\r\n")
	g_websocket_needs_restart = false
	g_ws = ws

	for ! g_websocket_needs_restart {
		// Read the message
		message_map, err := WebSocketRecieve()
		if (err != null) {
			fmt.Printf("Failed to get websocket message: %s\r\n", err)
			return
		}

		fmt.Printf("!!! action: %s\r\n", message_map["action"])

		// Client wants to play a game
		if message_map["action"] == "play" {
			playGame(message_map)

		// Client wants to download a file
		} else if message_map["action"] == "download" {
			downloadFile(message_map)

		// Client wants to know if a file is installed
		} else if message_map["action"] == "is_installed" {
			isInstalled(message_map)

		// Client wants to install a program
		} else if message_map["action"] == "install" {
			install(message_map)

		} else if message_map["action"] == "uninstall" {
			uninstall(message_map)

		} else if message_map["action"] == "set_button_map" {
			setButtonMap(message_map)

		} else if message_map["action"] == "get_button_map" {
			getButtonMap(message_map)

		} else if message_map["action"] == "set_bios" {
			setBios(message_map)

		} else if message_map["action"] == "get_db" {
			getDB()

		} else if message_map["action"] == "set_db" {
			var value map[string]map[string]map[string]object = null
			var err error = null

			if message_map["value"] != null {
				str_value :=  message_map["value"].(string)
				value, err = FromCompressedBase64Json(str_value)
				if (err != null) {
					panic(err)
				}

				setDB(value)
			} else {
				setDB(value)
			}

		} else if message_map["action"] == "get_directx_version" {
			getDirectXVersion()

		} else if message_map["action"] == "set_game_directory" {
			// First try checking if the browser is the foreground window
			hwnd := win32.GetForegroundWindow()
			text := win32.GetWindowText(hwnd)

			// If the focused window is not a known browser, find them manually
			if len(text)==0 ||
				! strings.Contains(text, " - Mozilla Firefox") &&
				! strings.Contains(text, " - Google Chrome") &&
				! strings.Contains(text, " - Opera") &&
				! strings.Contains(text, " ‎- Microsoft Edge") && // NOTE: The "-" is actually "â€Ž-" for some reason
				! strings.Contains(text, " - Internet Explorer") {
				// If not, find any Firefox window
				hwnd, text = win32.FindWindowWithTitleText(" - Mozilla Firefox")
				if hwnd < 1 || len(text)==0 {
					// If not, find any Chrome window
					hwnd, text = win32.FindWindowWithTitleText(" - Google Chrome")
					if hwnd < 1 || len(text)==0 {
						// If not, find any Opera window
						hwnd, text = win32.FindWindowWithTitleText(" - Opera")
						if hwnd < 1 || len(text)==0 {
							// If not, find any Microsoft Edge window
							hwnd, text = win32.FindWindowWithTitleText(" ‎- Microsoft Edge") // NOTE: The "-" is actually "â€Ž-" for some reason
							if hwnd < 1 || len(text)==0 {
								// If not, find any Internet Explorer window
								hwnd, text = win32.FindWindowWithTitleText(" - Internet Explorer")
								if hwnd < 1 || len(text)==0 {
									// If not, find the Desktop window
									hwnd = win32.GetDesktopWindow()
									text = "Desktop"
								}
							}
						}
					}
				}
			}
			if hwnd < 1 || len(text)==0 {
				panic("Failed to find any Firefox, Chrome, Opera, Edge, Internet Explorer, or the Desktop window to put the Folder Dialog on top of.\r\n")
			}

			// FIXME: How do we pass the string to display?
			browse_info := win32.BROWSEINFO {
				hwnd,
				null, //desktop_pidl,
				null,
				null, // "Select a folder search for games"
				0,
				0,
				0,
				0,
			}
			pidl := win32.SHBrowseForFolder(&browse_info)
			if pidl > 0 {
				message_map["directory_name"] = win32.SHGetPathFromIDList(pidl)
				go taskSetGameDirectory(message_map)
			}
		// Unknown message from the client
		} else {
			panic(fmt.Sprintf("Unknown action from client: %s\r\n", message_map["action"]))
		}
	}
	g_websocket_needs_restart = false
	http.Handle("/ws", websocket.Handler(webSocketCB))
}

func uncompress7Zip() {
	// Just return if 7zip already exists
	if helpers.IsFile("7za.exe") {
		return
	}

	// Get a blob of 7zip
	blob := generated.GetCompressed7zip()
	debug.FreeOSMemory()

	// Un Base64 the compressed gob
	zlibed_data, err := base64.StdEncoding.DecodeString(blob)
	blob = ""
	if (err != null) {
		panic(err)
	}
	zlibed_buffer := bytes.NewBuffer([]byte(zlibed_data))
	zlibed_data = zlibed_data[:0]
	debug.FreeOSMemory()

	// Un compress the gob
	var gob_buffer bytes.Buffer
	reader, err := zlib.NewReader(zlibed_buffer)
	if (err != null) {
		panic(err)
	}
	io.Copy(&gob_buffer, reader)
	reader.Close()
	zlibed_buffer.Reset()
	debug.FreeOSMemory()

	// Convert the gob to an array
	var file_data []byte
	decoder := gob.NewDecoder(&gob_buffer)
	err = decoder.Decode(&file_data)
	if (err != null) {
		panic(err)
	}
	gob_buffer.Reset()
	debug.FreeOSMemory()

	// Copy the file_data to an exe
	err = ioutil.WriteFile("7za.exe", file_data, 0644)
	if (err != null) {
		panic(err)
	}
	debug.FreeOSMemory()
}

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

func useAppDataForStaticFiles() {
	// Make the AppData/Local/emulators-online directory
	app_data := filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Local", "emulators-online")
	fmt.Printf("Storing static files in: %v\r\n", app_data)
	if ! helpers.IsDir(app_data) {
		os.Mkdir(app_data, os.ModeDir)
	}

	// Change to the AppData directory
	os.Chdir(app_data)

	// Make 7za.exe
	uncompress7Zip()

	// Make any directories if they don't exists
	dirs := []string {
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
	}
	for _, dir_name := range dirs {
		if ! helpers.IsDir(dir_name) {
			os.Mkdir(dir_name, os.ModeDir)
		}
	}

	// Get a blob of all the static files
	blob := generated.GetCompressedFiles()
	debug.FreeOSMemory()

	// Un Base64 the compressed gob map
	zlibed_data, err := base64.StdEncoding.DecodeString(blob)
	blob = ""
	if (err != null) {
		panic(err)
	}
	debug.FreeOSMemory()

	// Write the gob to file
	err = ioutil.WriteFile("gob.7z", zlibed_data, 0644)
	if (err != null) {
		panic(err)
	}

	// Uncompress the gob to file
	UncompressWith7zip("gob.7z")

	// Read the gob from file
	file_data, err := ioutil.ReadFile("gob")
	if (err != null) {
		panic(err)
	}
	debug.FreeOSMemory()

	// Convert the gob to the file map
	var file_map map[string][]byte
	buffer := bytes.NewBuffer([]byte(file_data))
	decoder := gob.NewDecoder(buffer)
	err = decoder.Decode(&file_map)
	if (err != null) {
		panic(err)
	}
	buffer.Reset()
	debug.FreeOSMemory()

	// Copy the file_map to files
	// FIXME: This copies the files for each run. Even if they are already there!
	// We need a way to quickly check if the files in the exe are different
    for file_name, data := range file_map {
		//if ! helpers.IsFile(file_name) {
			err := ioutil.WriteFile(file_name, data, 0644)
			if (err != null) {
				panic(err)
			}
		//}
    }

	// Remove the temp files
	os.Remove("gob")
	os.Remove("gob.7z")

	debug.FreeOSMemory()
}

func loadFileModifyDates() {
	// Load the file modify dates
	for _, console := range consoles {
		file_modify_dates[console] = map[string]int64{}
		file_name := fmt.Sprintf("cache/file_modify_dates_%s.json", console)
		if helpers.IsFile(file_name) {
			file_data, err := ioutil.ReadFile(file_name)
			if (err != null) {
				panic(err)
			}
			console_dates := file_modify_dates[console]
			err = json.Unmarshal(file_data, &console_dates)
			if (err != null) {
				panic(err)
			}

			// Remove any non existent files from the modify db
			keys := []string{}
			for k := range file_modify_dates[console] {
				keys = append(keys, k)
			}

			for _, entry := range keys {
				if ! helpers.IsFile(entry) {
					delete(file_modify_dates[console], entry)
				}
			}
		}
	}
}

func main() {
	// Catch any panics to show to user
	defer helpers.RecoverPanicTo(func(message string) {
		fmt.Fprintf(os.Stderr, "%v\n", message)
	})

	// Set what game consoles to support
	consoles = []string{
		"dreamcast",
		"playstation2",
	}

	// Initialize the globals
	db = make(map[string]map[string]map[string]object)
	file_modify_dates = map[string]map[string]int64{}
	long_running_tasks = map[string]LongRunningTask{}

	for _, console := range consoles {
		db[console] = make(map[string]map[string]object)
		file_modify_dates[console] = map[string]int64{}
	}

	demul = helpers.NewDemul()
	pcsx2 = helpers.NewPCSX2()

	// Get the websocket port from the args
	var ws_port int64 = 9090
	var err error
	if len(os.Args) >= 2 {
		ws_port, err = strconv.ParseInt(os.Args[1], 10, 0)
		if (err != null) {
			panic(err)
		}
	}

	// If "local" use the static files in the current directory
	// If not use the static files in AppData
	if len(os.Args) < 3 || os.Args[2] != "local" {
		useAppDataForStaticFiles()
	} else {
		// Make 7za.exe
		uncompress7Zip()
	}

	// Get the DirectX Version
	helpers.StartBackgroundSearchForDirectXVersion()

	server_address := fmt.Sprintf("127.0.0.1:%v", ws_port)
	http.Handle("/ws", websocket.Handler(webSocketCB))
	http.HandleFunc("/", httpCB)
	fmt.Printf("Server running at: http://%s\r\n",  server_address)
	err = http.ListenAndServe(server_address, null)
	if (err != null) {
		panic(err)
	}
}
