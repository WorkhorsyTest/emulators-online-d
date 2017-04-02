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
/*
import (
	"fmt"
	//"archive/zip"
	//"time"
	"./helpers"
	"strings"
	"io/ioutil"
	"path/filepath"
	"os"
	"errors"
	"runtime"
	"encoding/json"
	"strconv"
)
*/

const ulong BUFFER_SIZE = 1024 * 1024 * 10;
string[string][string] unofficial_db;
string[string][string] official_us_db;
string[string][string] official_eu_db;
string[string][string] official_jp_db;


string _strip_comments(string data) {
	import std.string;
	import std.array;
	import std.algorithm.searching;

	string[] lines = strings.Split(data, "\r\n");
	string[] new_data;
	foreach (line ; lines) {
		if (! line.canFind("/*") && ! line.canFind("*/")) {
			new_data ~= line;
		}
	}

	return new_data.join("\r\n");
}

string _read_blob_at(file File, ulong start_address, byte[] buffer, ulong size) {
	file.Seek(start_address, 0);
	ulong length = file.read(buffer);

	if (size < length) {
		throw new Exception("Read size was less than the desired size.");
	}
	return cast(string) buffer[0 .. size];
}

func _load_json(file_name string, load_into *map[string] map[string]string) {
	// Read the json file
	data, err := ioutil.ReadFile(file_name)
	if err != nil {
		panic(err)
	}

	// Strip the comments and load the json into the map
	//var retval map[string]string
	data = []byte(_strip_comments(string(data)))
	//fmt.Printf("!!! data: %s\n", data)
	err = json.Unmarshal(data, &load_into)
	if err != nil {
		panic(err)
	}
}

func _fix_games_with_same_serial_number(f *os.File, title string, serial_number string) (string, string) {
	if serial_number == "T-8111D-50" {
		if title == "ECW HARDCORE REVOLUTION" { // EU ECW Hardcore Revolution
			return "ECW Hardcore Revolution", "T-8111D-50"
		} else if title == "DEAD OR ALIVE 2" { // EU Dead or Alive 2
			return "Dead or Alive 2", "T-8111D-50"
		}
	} else if serial_number == "T-8101N" {
		if title == "QUARTERBACK CLUB 2000" { //US NFL Quarterback Club 2000
			return "NFL Quarterback Club 2000", "T-8101N"
		} else if title == "JEREMY MCGRATH SUPERCROSS 2000" { //US Jeremy McGrath Supercross 2000
			return "Jeremy McGrath Supercross 2000", "T-8101N"
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
	return title, serial_number
}

func _fix_games_that_are_mislabeled(f *os.File, title string, serial_number string) (string, string) {
	buffer := make([]byte, 30)
	if serial_number == "T1402N" { // Mr. Driller
		if name, _ := _read_blob_at(f, 0x159208, buffer, 12); name == "DYNAMITE COP" {
			return "Dynamite Cop!", "MK-51013"
		}
	} else if serial_number == "MK-51035" { // Crazy Taxi
		if name, _ := _read_blob_at(f, 0x1617E652, buffer, 9); name == "Half-Life" {
			return "Half-Life", "T0000M"
		} else if name, _ := _read_blob_at(f, 0x1EA78B5, buffer, 10); name == "Shadow Man" {
			return "Shadow Man", "T8106N"
		}
	} else if serial_number == "T43903M" { // Culdcept II
		if name, _ := _read_blob_at(f, 0x264E1E5D, buffer, 10); name == "CHAOSFIELD" {
			return "Chaos Field", "T47801M"
		}
	} else if serial_number == "T0000M" { // Unnamed
		if name, _ := _read_blob_at(f, 0x557CAB0, buffer, 13); name == "BALL BREAKERS" {
			return "Ball Breakers", "T0000M"
		} else if name, _ := _read_blob_at(f, 0x4BD5EE5, buffer, 6); name == "TOEJAM" {
			return "ToeJam and Earl 3", "T0000M"
		}
	} else if serial_number == "T0000" { // Unnamed
		if name, _ := _read_blob_at(f, 0x162E20, buffer, 15); name == "Art of Fighting" {
			return "Art of Fighting", "T0000"
		} else if name, _ := _read_blob_at(f, 0x29E898B0, buffer, 17); name == "Art of Fighting 2" {
			return "Art of Fighting 2", "T0000"
		} else if name, _ := _read_blob_at(f, 0x26D5BCA4, buffer, 17); name == "Art of Fighting 3" {
			return "Art of Fighting 3", "T0000"
		} else if name, _ := _read_blob_at(f, 0x295301F0, buffer, 5); name == "Redux" {
			return "Redux: Dark Matters", "T0000"
		}
	} else if serial_number == "MK-51025" { // NHL 2K1
		if name, _ := _read_blob_at(f, 0x410CA8, buffer, 14); name == "READY 2 RUMBLE" {
			return "Ready 2 Rumble Boxing", "T9704N"
		}
	} else if serial_number == "T36804N" { // Walt Disney World Quest: Magical Racing Tour
		if name, _ := _read_blob_at(f, 0x245884, buffer, 6); name == "MakenX" {
			return "Maken X", "MK-51050"
		}
	} else if serial_number == "RDC-0117" { // The king of Fighters '96 Collection (NEO4ALL RC4)
		if name, _ := _read_blob_at(f, 0x159208, buffer, 16); name == "BOMBERMAN ONLINE" {
			return "Bomberman Online", "RDC-0120"
		}
	} else if serial_number == "RDC-0140" { // Dead or Alive 2
		if name, _ := _read_blob_at(f, 0x15639268, buffer, 13); name == "CHUCHU ROCKET" {
			return "ChuChu Rocket!", "RDC-0139"
		}
	} else if serial_number == "T19724M" { // Pizzicato Polka: Suisei Genya
		if name, _ := _read_blob_at(f, 0x3CA16B8, buffer, 7); name == "DAYTONA" {
			return "Daytona USA", "MK-51037"
		}
	} else if serial_number == "MK-51049" { // ChuChu Rocket!
		if name, _ := _read_blob_at(f, 0xC913DDC, buffer, 13); name == "HYDRO THUNDER" {
			return "Hydro Thunder", "T9702N"
		} else if name, _ := _read_blob_at(f, 0x2D096802, buffer, 17); name == "MARVEL VS. CAPCOM" {
			return "Marvel vs. Capcom 2", "T1212N"
		} else if name, _ := _read_blob_at(f, 0x1480A730, buffer, 13); name == "POWER STONE 2" {
			return "Power Stone 2", "T-1211N"
		}
	} else if serial_number == "T44304N" { // Sports Jam
		if name, _ := _read_blob_at(f, 0x157FA8, buffer, 9); name == "OUTRIGGER" {
			return "OutTrigger: International Counter Terrorism Special Force", "MK-51102"
		}
	} else if serial_number == "MK-51028" { // Virtua Striker 2
		if name, _ := _read_blob_at(f, 0x1623B0, buffer, 12); name == "zerogunner 2" {
			return "Zero Gunner 2", "MK-51028"
			//return "OutTrigger: International Counter Terrorism Special Force", "MK-51102"
		}
	} else if serial_number == "T1240M" { // BioHazard Code: Veronica Complete
		if name, _ := _read_blob_at(f, 0x157FAD, buffer, 14); name == "BASS FISHING 2" {
			return "Sega Bass Fishing 2", "MK-51166"
		}
	} else if serial_number == "MK-51100" { // Phantasy Star Online
		if name, _ := _read_blob_at(f, 0x52F28A8, buffer, 26); name == "Phantasy Star Online Ver.2" {
			return "Phantasy Star Online Ver. 2", "MK-51166"
		}
	}

	return title, serial_number
}


func _locate_string_in_file(f *os.File, file_size int64, buffer []byte, string_to_find string) (int64, error) {
	var string_length int64 = int64(len(string_to_find))
	f.Seek(0, 0)
	pos := 0
	for {
		// Read into the buffer
		data_length, err := f.Read(buffer)
		if err != nil {
			return -1, err
		}
		pos += data_length
		rom_data := string(buffer[0 : data_length])

		// Check for the end of the file
		if len(rom_data) < 1 {
			break
		}

		// Figure out if we need an offset
		var file_pos int64 = int64(pos)
		use_offset := false
		if file_pos > string_length && file_pos < file_size {
			use_offset = true
		}

		// Get the string to find location
		index := strings.Index(rom_data, string_to_find)
		if index > -1 {
			string_file_location := (file_pos - int64(len(rom_data))) + int64(index)
			return string_file_location, nil
		}

		// Move back the length of the string to find
		// This is done to stop the string to find from being spread over multiple buffers
		if use_offset {
			f.Seek(file_pos - string_length, 0)
		}
	}

	return -1, nil
}

func _get_track_01_from_gdi_file(file_name string, buffer []byte) (string, error) {
	path := filepath.Dir(file_name)

	f, err := os.Open(file_name)
	if err != nil {
		return "", err
	}
	defer f.Close()

	length, err := f.Read(buffer)
	if err != nil {
		return "", err
	}
	track := string(buffer[0 : length])
	track_01_line := strings.Split(track, "\r\n")[1]
	track_01_file := strings.Split(track_01_line, " ")[4]
	track_01_file = filepath.Join(path, track_01_file)
	return track_01_file, nil
}

func IsDreamcastFile(game_file string) bool {
	// Skip if not file
	if ! helpers.IsFile(game_file) {
		return false
	}

	// FIXME: Make it work with .mdf/.mds, .nrg, and .ccd/.img
	// Skip if not a usable file
	good_exts := [...]string {".cdi", ".gdi", ".iso"}
	ext := strings.ToLower(filepath.Ext(game_file))
	for _, good_ext := range good_exts {
		if ext == good_ext {
			return true
		}
	}

	return false
}

func GetDreamcastGameInfo(game_file string) (map[string]string, error) {
	// Get the full file name
	full_entry, err := filepath.Abs(game_file)
	if err != nil {
		return nil, err
	}

	// If it's a GDI file read track 01
	small_buffer := make([]byte, 256)
	if strings.ToLower(filepath.Ext(full_entry)) == ".gdi" {
		full_entry, err = _get_track_01_from_gdi_file(full_entry, small_buffer)
		if err != nil {
			return nil, err
		}
	}

	// Open the game file
	f, err := os.Open(full_entry)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	// Get the file size
	file_info, err := f.Stat()
	if err != nil {
		return nil, err
	}
	file_size := file_info.Size()

	// Get the location of the header
	header_text := "SEGA SEGAKATANA SEGA ENTERPRISES"
	buffer := make([]byte, BUFFER_SIZE)
	index, err := _locate_string_in_file(f, file_size, buffer, header_text)
	if err != nil {
		return nil, err
	}
	// Throw if index not found
	if index == -1 {
		return nil, errors.New("Failed to find Sega Dreamcast Header.")
	}

	// Read the header
	_, err = f.Seek(index, 0)
	if err != nil {
		return nil, err
	}
	length, err := f.Read(small_buffer)
	if err != nil {
		return nil, err
	}
	header := string(small_buffer[0 : length])

	// Parse the header info
	offset := len(header_text)
	disc_info := strings.TrimSpace(header[offset + 5 : offset + 5 + 11])
	region := strings.TrimSpace(header[offset + 14 : offset + 14 + 10])
	serial_number := strings.TrimSpace(header[offset + 32 : offset + 32 + 10])
	version := strings.TrimSpace(header[offset + 42 : offset + 42 + 22])
	boot := strings.TrimSpace(header[offset + 64 : offset + 64 + 16])
	maker := strings.TrimSpace(header[offset + 80 : offset + 80 + 16])
	sloppy_title := strings.TrimSpace(header[offset + 96 : ])
	var title string
	var developer string
	var genre string
	var publisher string
	var release_date string

	// Remove trailing zeros
	if strings.HasSuffix(serial_number, " 00") {
		serial_number = strings.TrimRight(serial_number, " 00")
		serial_number = strings.TrimSpace(serial_number)
	}

	// Remove any spaces and dashes
	serial_number = strings.Replace(serial_number, "-", "", -1)
	serial_number = strings.Replace(serial_number, " ", "", -1)
	serial_number = strings.TrimSpace(serial_number)

/*
	fmt.Printf("offset: %v\n", offset)
	fmt.Printf("disc_info: %v\n", disc_info)
	fmt.Printf("region: %v\n", region)
	fmt.Printf("serial_number: %v\n", serial_number)
	fmt.Printf("version: %v\n", version)
	fmt.Printf("boot: %v\n", boot)
	fmt.Printf("marker: %v\n", maker)
	fmt.Printf("sloppy_title: %v\n", sloppy_title)
	fmt.Printf("index: %s\n", strconv.FormatInt(index, 10))
*/
	// Check for different types of releases

	// Unofficial
	var info map[string]string
	if value, ok := unofficial_db[serial_number]; ok {
		info = value
	// US
	} else if value, ok := official_us_db[serial_number]; ok {
		info = value
	// Europe
	} else if value, ok := official_eu_db[serial_number]; ok {
		info = value
	// Japan
	} else if value, ok := official_jp_db[serial_number]; ok {
		info = value
	}

	if len(info) > 0 {
		title = info["title"]
		developer = info["developer"]
		genre = info["genre"]
		publisher = info["publisher"]
		release_date = info["release_date"]
	}

	// Check for games with the same serial number
	title, serial_number = _fix_games_with_same_serial_number(f, title, serial_number)

	// Check for mislabeled releases
	title, serial_number = _fix_games_that_are_mislabeled(f, title, serial_number)

	// Throw if the title is not found in the database
	if len(title) == 0 {
		return nil, errors.New("Failed to find game in database.")
	}

	retval := map[string]string {
		"title" : title,
		"disc_info" : disc_info,
		"region" : region,
		"serial_number" : serial_number,
		"version" : version,
		"boot" : boot,
		"maker" : maker,
		"developer" : developer,
		"genre" : genre,
		"publisher" : publisher,
		"release_date" : release_date,
		"sloppy_title" : sloppy_title,
		"header_index" : strconv.FormatInt(index, 10),
	}

	return retval, nil
}

func mainXXX() {
	// Catch any panics to show to user
	/*
	defer helpers.RecoverPanicTo(func(message string) {
		fmt.Fprintf(os.Stderr, "%v\n", message)
	})
	*/

	// Get the path of the current file
	_, root, _, _ := runtime.Caller(0)
	root = filepath.Dir(root)

	_load_json(filepath.Join(root, "db_dreamcast_unofficial.json"), &unofficial_db)
	_load_json(filepath.Join(root, "db_dreamcast_official_us.json"), &official_us_db)
	_load_json(filepath.Join(root, "db_dreamcast_official_jp.json"), &official_jp_db)
	_load_json(filepath.Join(root, "db_dreamcast_official_eu.json"), &official_eu_db)
///*
	games_root := "C:/Users/matt/Desktop/Dreamcast"
	filepath.Walk(games_root, func(path string, _ os.FileInfo, _ error) error {
		// Skip if not a Dreamcast game
		if ! IsDreamcastFile(path) {
			return nil
		}

		info, err := GetDreamcastGameInfo(path)
		if err != nil {
			fmt.Printf("Failed to find: %s\r\n", path)
			return nil
		}

		fmt.Printf("title: %s\r\n", info["title"])
		return nil
	})
//*/
/*
	path := "C:/Users/matt/Desktop/Dreamcast/Sonic Adventure 2/sonic_adventure_2.cdi"
	path = "C:/Users/matt/Desktop/Dreamcast/18 Wheeler - American Pro Trucker/18 Wheeler - American Pro Trucker v1.500 (2001)(Sega)(NTSC)(US)[!].gdi"
	info, err := GetDreamcastGameInfo(path)
	if err != nil {
		fmt.Printf("err: %s\r\n", err)
		return
	}

	fmt.Printf("path: %s\r\n", path)
	fmt.Printf("title: %s\r\n", info["title"])
	fmt.Printf("disc_info: %s\r\n", info["disc_info"])
	fmt.Printf("region: %s\r\n", info["region"])
	fmt.Printf("serial_number: %s\r\n", info["serial_number"])
	fmt.Printf("version: %s\r\n", info["version"])
	fmt.Printf("boot: %s\r\n", info["boot"])
	fmt.Printf("maker: %s\r\n", info["maker"])
	fmt.Printf("developer: %s\r\n", info["developer"])
	fmt.Printf("genre: %s\r\n", info["genre"])
	fmt.Printf("publisher: %s\r\n", info["publisher"])
	fmt.Printf("release_date: %s\r\n", info["release_date"])
	fmt.Printf("sloppy_title: %s\r\n", info["sloppy_title"])
	fmt.Printf("header_index: %s\r\n", info["header_index"])
*/
}
