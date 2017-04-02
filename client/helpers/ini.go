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
	"io/ioutil"
	"strings"
	"os"
	"fmt"
)


func ReadIniFile(file_path string) (map[string]map[string]interface{}, error) {
	data, err := ioutil.ReadFile(file_path)
	if err != nil {
		return nil, err
	}
	ini_data := string(data)
	var config map[string]map[string]interface{}

	// Read the ini file into a dictionary
	var header string
	for _, line := range strings.Split(ini_data, "\r\n") {
		// Line is a header
		if strings.Contains(line, "[") && strings.Contains(line, "]") {
			header = Between(line, "[", "]")
		// Line is a key value pair
		} else if strings.Contains(line, " = ") {
			pair := strings.Split(line, " = ")
			key, value := pair[0], pair[1]
			config[header][key] = value
		}
	}

	return config, err
}


func WriteIniFile(file_name string, config map[string]map[string]interface{}) error {
	f, err := os.Create(file_name)
	if err != nil {
		panic(err)
		return err
	}
	defer f.Close()

	// First add any fields with no master
	if pairs, ok := config[""]; ok {
		// Keys and values
		for key, value := range pairs {
			formatted_entry := fmt.Sprintf("%s = %v\r\n", key, value)
			f.Write([]byte(formatted_entry))
		}
	}

	// Add fields with a master
	for header, pairs := range config {
		// Skip if there is no master
		if header == "" {
			continue
		}

		// Header
		formatted_header := fmt.Sprintf("[%s]\r\n", header)
		f.Write([]byte(formatted_header))

		// Keys and values
		for key, value := range pairs {
			formatted_entry := fmt.Sprintf("%s = %v\r\n", key, value)
			f.Write([]byte(formatted_entry))
		}

		// Two spaces at the end of a section
		f.Write([]byte("\r\n\r\n"))
	}

	return nil
}
