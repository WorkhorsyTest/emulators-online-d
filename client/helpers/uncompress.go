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

import (
	"strings"
	"fmt"
	//"os"
	"os/exec"
	"bytes"
)

func Uncompress(compressed_file string, out_dir string) {
	//fmt.Printf("!!!!!!!!!!!!!! uncomressing!\r\n")
	var command string
	var args []string

	if strings.HasSuffix(compressed_file, ".7z") || strings.HasSuffix(compressed_file, ".zip"){
		// Get the command and arguments
		command = "7za.exe"
		args = []string {
			"x",
			"-y",
			fmt.Sprintf(`%s`, compressed_file),
			fmt.Sprintf("-o%s", out_dir),
		}
	} else if strings.HasSuffix(compressed_file, ".rar") {
		// Get the command and arguments
		command = "unrar.exe"
		args = []string {
			"x",
			"-y",
			fmt.Sprintf(`%s`, compressed_file),
			fmt.Sprintf("%s", out_dir),
		}
	}

	// Run the command and wait for it to complete
	cmd := exec.Command(command, args...)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("Failed to run command: %s\r\n", err)
		fmt.Printf("stdout: %s\r\n", stdout.Bytes())
		fmt.Printf("stderr: %s\r\n", stderr.Bytes())
	}
}






