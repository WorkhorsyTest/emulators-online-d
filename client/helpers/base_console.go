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
	//"fmt"
	"strings"
	"io/ioutil"
	"path/filepath"
	"os"
	//"runtime"
	//"os/exec"
	//"encoding/base64"
	"encoding/json"
)


type BaseConsole struct {
	config_path string
	button_map map[string]string
}

func NewBaseConsole(config_path string) *BaseConsole {
	self := &BaseConsole{}
	self.config_path = config_path

	// Load the config
	if IsFile(self.config_path) {
		data, err := ioutil.ReadFile(self.config_path)
		if err != nil {
			panic(err)
		}
		err = json.Unmarshal(data, &self.button_map)
		if err != nil {
			panic(err)
		}
	}

	return self
}

func (self *BaseConsole) SetButtonMap(button_map map[string]string) error {
	self.button_map = button_map

	// Open the file
	f, err := os.Create(self.config_path)
	if err != nil {
		return err
	}
	defer f.Close()

	// Convert the button map to json
	jsoned_data, err := json.MarshalIndent(self.button_map, "", "\t")
	if err != nil {
		return err
	}

	// Write the jsoned button map to file
	f.Write([]byte(jsoned_data))

	return nil
}

func (self *BaseConsole) GetButtonMap() map[string]string {
	return self.button_map
}

func (self *BaseConsole) goodJoin(path_a string, path_b string) string {
	path := path_a + path_b
	path, _ = filepath.Abs(path)
	path = strings.Replace(path, "\\", "/", -1)
	return path
}
