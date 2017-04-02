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

package helpers

import(
	"strings"
	"fmt"
	"io/ioutil"
	"os/exec"
	"bytes"
)

var g_directx_version int
var g_version_channel chan int

func findDirectxVersion(version_channel chan int) {
	// Run dxdiag and write its output to a file
	cmd := exec.Command("dxdiag.exe", "/t", "directx_info.txt")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		panic(fmt.Sprintf("Failed to determine DirectX version: %s\r\n", err))
	}

	// Get the info from the file
	data, err := ioutil.ReadFile("directx_info.txt")
	if err != nil {
		panic(fmt.Sprintf("Failed to determine DirectX version: %s\r\n", err))
	}
	string_data := string(data)
	raw_version := Between(string_data, "DirectX Version: ", "\r\n")

	// Get the DirectX version
	var version int
	if strings.Contains(raw_version, "12") {
		version = 12
	} else if strings.Contains(raw_version, "11") {
		version = 11
	} else if strings.Contains(raw_version, "10") {
		version = 10
	} else if strings.Contains(raw_version, "9") {
		version = 9
	} else {
		panic("Failed to determine DirectX version.\r\n")
	}

	version_channel <- version
}

func GetDirectXVersion() int {
	// Return the version if we already have it
	if g_directx_version > 0 {
		return g_directx_version
	}

	// Otherwise wait here for the version
	g_directx_version = <- g_version_channel
	return g_directx_version
}

func StartBackgroundSearchForDirectXVersion() {
	// Start the goroutine that looks up the DirectX version
	g_version_channel = make(chan int)
	go findDirectxVersion(g_version_channel)
}
