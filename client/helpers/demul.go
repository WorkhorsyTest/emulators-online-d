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
	"os"
	"fmt"
	"io/ioutil"
	"path/filepath"
)


var BUTTON_CODE_MAP map[string]int64

// Figure out the DirectX version
var gpu_dll_version string
var directx_version int

type Demul struct {
	*BaseConsole
}

func NewDemul() *Demul {
	self := &Demul{}
	self.BaseConsole = NewBaseConsole("config/demul.json")

	// Setup the initial map, if there is none
	if self.button_map == nil {
		self.button_map = map[string]string {
			"btn_up_demul" : "",
			"btn_down_demul" : "",
			"btn_left_demul" : "",
			"btn_right_demul" : "",
			"btn_start_demul" : "",
			"btn_a_demul" : "",
			"btn_b_demul" : "",
			"btn_x_demul" : "",
			"btn_y_demul" : "",
			"btn_l_trigger_demul" : "",
			"btn_r_trigger_demul" : "",
			"btn_left_stick_up_demul" : "",
			"btn_left_stick_down_demul" : "",
			"btn_left_stick_left_demul" : "",
			"btn_left_stick_right_demul" : "",
			"btn_right_stick_up_demul" : "",
			"btn_right_stick_down_demul" : "",
			"btn_right_stick_left_demul" : "",
			"btn_right_stick_right_demul" : "",
			"select_directx_version" : "",
		}
	}

	return self
}

func (self *Demul) IsInstalled() bool {
	return IsDir("emulators/Demul/")
}

func (self *Demul) setupPad() {
		config := map[string]map[string]interface{} {
			"JOY0_0" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JOY0_1" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JOY0_2" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JOY0_3" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JAMMA0_0" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"JAMMA0_1" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"JAMMA0_2" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"JAMMA0_3" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"MAHJONG0_0" : {
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"E" : 0,
				"F" : 0,
				"G" : 0,
				"H" : 0,
				"I" : 0,
				"J" : 0,
				"K" : 0,
				"L" : 0,
				"M" : 0,
				"N" : 0,
				"FF" : 0,
				"STR" : 0,
				"BET" : 0,
				"LST" : 0,
				"KAN" : 0,
				"PON" : 0,
				"CHI" : 0,
				"RCH" : 0,
				"RON" : 0,
			},
			"GLOBAL0" : {
				"TEST" : 0,
				"TEST2" : 0,
				"SERVICE" : 0,
				"SAVESTATE" : 0,
				"LOADSTATE" : 0,
				"NEXTSTATE" : 0,
				"PREVSTATE" : 0,
				"DEADZONE" : 0,
			},
			"JOY1_0" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JOY1_1" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JOY1_2" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JOY1_3" : {
				"UP" : 0,
				"DOWN" : 0,
				"LEFT" : 0,
				"RIGHT" : 0,
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"X" : 0,
				"Y" : 0,
				"Z" : 0,
				"LTRIG" : 0,
				"RTRIG" : 0,
				"START" : 0,
				"S1UP" : 0,
				"S1DOWN" : 0,
				"S1LEFT" : 0,
				"S1RIGHT" : 0,
				"S2UP" : 0,
				"S2DOWN" : 0,
				"S2LEFT" : 0,
				"S2RIGHT" : 0,
			},
			"JAMMA1_0" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"JAMMA1_1" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"JAMMA1_2" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"JAMMA1_3" : {
				"PUSH1" : 0,
				"PUSH2" : 0,
				"PUSH3" : 0,
				"PUSH4" : 0,
				"PUSH5" : 0,
				"PUSH6" : 0,
				"PUSH7" : 0,
				"PUSH8" : 0,
				"SERVICE" : 0,
				"START" : 0,
				"COIN" : 0,
				"DIGITALUP" : 0,
				"DIGITALDOWN" : 0,
				"DIGITALLEFT" : 0,
				"DIGITALRIGHT" : 0,
				"ANALOGUP" : 0,
				"ANALOGDOWN" : 0,
				"ANALOGLEFT" : 0,
				"ANALOGRIGHT" : 0,
				"ANALOGUP2" : 0,
				"ANALOGDOWN2" : 0,
				"ANALOGLEFT2" : 0,
				"ANALOGRIGHT2" : 0,
			},
			"MAHJONG01_0" : {
				"A" : 0,
				"B" : 0,
				"C" : 0,
				"D" : 0,
				"E" : 0,
				"F" : 0,
				"G" : 0,
				"H" : 0,
				"I" : 0,
				"J" : 0,
				"K" : 0,
				"L" : 0,
				"M" : 0,
				"N" : 0,
				"FF" : 0,
				"STR" : 0,
				"BET" : 0,
				"LST" : 0,
				"KAN" : 0,
				"PON" : 0,
				"CHI" : 0,
				"RCH" : 0,
				"RON" : 0,
			},
			"GLOBAL1" : {
				"TEST" : 0,
				"TEST2" : 0,
				"SERVICE" : 0,
				"SAVESTATE" : 0,
				"LOADSTATE" : 0,
				"NEXTSTATE" : 0,
				"PREVSTATE" : 0,
				"DEADZONE" : 0,
			},
		}

		// Setup the gamepad
		config["JOY0_0"] = map[string]interface{} {
			"UP" : BUTTON_CODE_MAP[self.button_map["btn_up_demul"]],
			"DOWN" : BUTTON_CODE_MAP[self.button_map["btn_down_demul"]],
			"LEFT" : BUTTON_CODE_MAP[self.button_map["btn_left_demul"]],
			"RIGHT" : BUTTON_CODE_MAP[self.button_map["btn_right_demul"]],
			"A" : BUTTON_CODE_MAP[self.button_map["btn_a_demul"]],
			"B" : BUTTON_CODE_MAP[self.button_map["btn_b_demul"]],
			"C" : 0,
			"D" : 0,
			"X" : BUTTON_CODE_MAP[self.button_map["btn_x_demul"]],
			"Y" : BUTTON_CODE_MAP[self.button_map["btn_y_demul"]],
			"Z" : 0,
			"LTRIG" : BUTTON_CODE_MAP[self.button_map["btn_l_trigger_demul"]],
			"RTRIG" : BUTTON_CODE_MAP[self.button_map["btn_r_trigger_demul"]],
			"START" : BUTTON_CODE_MAP[self.button_map["btn_start_demul"]],
			"S1UP" : BUTTON_CODE_MAP[self.button_map["btn_left_stick_up_demul"]],
			"S1DOWN" : BUTTON_CODE_MAP[self.button_map["btn_left_stick_down_demul"]],
			"S1LEFT" : BUTTON_CODE_MAP[self.button_map["btn_left_stick_left_demul"]],
			"S1RIGHT" : BUTTON_CODE_MAP[self.button_map["btn_left_stick_right_demul"]],
			"S2UP" : BUTTON_CODE_MAP[self.button_map["btn_right_stick_up_demul"]],
			"S2DOWN" : BUTTON_CODE_MAP[self.button_map["btn_right_stick_down_demul"]],
			"S2LEFT" : BUTTON_CODE_MAP[self.button_map["btn_right_stick_left_demul"]],
			"S2RIGHT" : BUTTON_CODE_MAP[self.button_map["btn_right_stick_right_demul"]],
		}

		WriteIniFile("emulators/Demul/padDemul.ini", config)
}

func (self *Demul) setupSpu() {
	config := map[string]map[string]interface{} {
		"main" : {
			"spuDisable" : "false",
			"cddaDisable" : "false",
			"dspDisable" : "false",
			"spuRecord" : "false",
			"bufSize" : 2048,
		},
	}
	WriteIniFile("emulators/Demul/spuDemul.ini", config)
}

func (self *Demul) setupNet() {
	config := map[string]map[string]interface{} {
		"main" : {
			"netEnable" : "false",
			"swapDisable" : "false",
			"NameOverride" : "",
		},
	}
	WriteIniFile("emulators/Demul/netDemul.ini", config)
}

func (self *Demul) setupGdr() {
		config := map[string]map[string]interface{} {
			"main" : {
				"imageFileName" : "",
				"openDialog" : "false",
			},
		}
		WriteIniFile("emulators/Demul/gdrImage.ini", config)
}

func (self *Demul) setupDirectx() {
		// Setup DirectX
		config := map[string]map[string]interface{} {
			"main" : {
				"Vsync" : 0,
				"AutoSort" : 0,
				"NetworkSort" : 0,
				"OModifier" : 0,
				"TModifier" : 0,
				"UseFullscreen" : 0,
				"rotate" : 0,
				"aspect" : 1,
				"scaling" : 1,
				"MaxLayers" : 32,
				"NotAutoRotate" : 0,
			},
			"resolution" : {
				"Width" : 640,
				"Height" : 480,
			},
			"shaders" : {
				"usePass1" : 0,
				"usePass2" : 0,
				"shaderPass1" : "",
				"shaderPass2" : "",
			},
		}

		if directx_version == 11 {
			WriteIniFile("emulators/Demul/gpuDX11.ini", config)
		} else if directx_version == 10 {
			WriteIniFile("emulators/Demul/gpuDX10.ini", config)
		} else {
			panic("Failed to determine DirectX version.\r\n")
		}
}

func (self *Demul) setupDemul() map[string]map[string]interface{} {
		// Setup Demul
		files_nvram, _ := filepath.Abs("emulators/Demul/nvram/")
		files_roms0, _ := filepath.Abs("emulators/Demul/roms/")
		plugins_directory, _ := filepath.Abs("emulators/Demul/plugins/")
		vms_vmsa0, _ := filepath.Abs("emulators/Demul/memsaves/vms00.bin")

		config := map[string]map[string]interface{} {
			"main" : {
				"region" : 1,
				"broadcast" : 1,
				"cpumode" : 1,
				"lastEmuRunMode" : 0,
				"videomode" : 768,
				"timehack" : "true",
				"activateBBA" : "false",
				"VMUscreendisable" : "false",
				"windowX" : 100,
				"windowY" : 100,
				"dcBios" : 3,
				"naomiBiosAuto" : "true",
				"naomiLLEMIE" : "false",
				"naomifreq" : 1,
				"hikaruBios" : 1,
			},
			"PORTA" : {
				"device" : 16777216,
				"port0" : 234881024,
				"port1" : 65536,
				"port2" : -1,
				"port3" : -1,
				"port4" : -1,
			},
			"VMS" : {
				"VMSA0" : vms_vmsa0,
				"VMSA1" : "",
				"VMSA2" : "",
				"VMSA3" : "",
				"VMSA4" : "",
				"VMSB0" : "",
				"VMSB1" : "",
				"VMSB2" : "",
				"VMSB3" : "",
				"VMSB4" : "",
				"VMSC0" : "",
				"VMSC1" : "",
				"VMSC2" : "",
				"VMSC3" : "",
				"VMSC4" : "",
				"VMSD0" : "",
				"VMSD1" : "",
				"VMSD2" : "",
				"VMSD3" : "",
				"VMSD4" : "",
			},
			"PORTB" : {
				"device" : -1,
				"port0" : -1,
				"port1" : -1,
				"port2" : -1,
				"port3" : -1,
				"port4" : -1,
			},
			"PORTC" : {
				"device" : -1,
				"port0" : -1,
				"port1" : -1,
				"port2" : -1,
				"port3" : -1,
				"port4" : -1,
			},
			"PORTD" : {
				"device" : -1,
				"port0" : -1,
				"port1" : -1,
				"port2" : -1,
				"port3" : -1,
				"port4" : -1,
			},
			"plugins" : {
				"directory" : plugins_directory,
				"gdr" : "gdrImage.dll",
				"gpu" : gpu_dll_version,
				"spu" : "spuDemul.dll",
				"pad" : "padDemul.dll",
				"net" : "netDemul.dll",
			},
			"files" : {
				"nvram" : files_nvram,
				"roms0" : files_roms0,
				"romsPathsCount" : 1,
			},
		}
		WriteIniFile("emulators/Demul/Demul.ini", config)
		return config
}

func (self *Demul) Run(path string, binary string, on_stop func(memory_card []byte)) {
	directx_version = GetDirectXVersion()

	if directx_version == 11 {
		gpu_dll_version = "gpuDX11.dll"
	} else if directx_version == 10 {
		gpu_dll_version = "gpuDX10.dll"
	} else {
		panic("Failed to determine DirectX version.\r\n")
	}

	// Setup ini files
	self.setupSpu()
	self.setupPad()
	self.setupNet()
	self.setupGdr()
	self.setupDirectx()
	config := self.setupDemul()

	// Get the window title
	directx_dll := config["plugins"]["gpu"]
	var window_name string
	if path=="" && binary=="" {
		window_name = "Demul"
	} else if directx_dll == "gpuDX11.dll" {
		window_name = "gpuDX11"
	} else if directx_dll == "gpuDX10.dll" {
		window_name = "gpuDX10"
	}

	os.Chdir("emulators/Demul/")

	// Figure out if running a game or not
	var command CommandWithArgs
	full_screen := false
	if binary != "" {
		name := "demul.exe"
		args := []string {"-run=dc", fmt.Sprintf("-image=%s", binary)}
		command = CommandWithArgs {name, args}
		full_screen = true
	} else {
		name := "demul.exe"
		args := []string {"-run=dc"}
		command = CommandWithArgs {name, args}
		full_screen = false
	}

	// Run the game
	var runner EmuRunner
	full_screen_alt_enter := true
	runner.Setup(command, window_name, full_screen, full_screen_alt_enter)
	runner.Run()
	os.Chdir("../..")

	// Upload the memory card to the server
	if on_stop != nil {
		memory_card, _ := ioutil.ReadFile("emulators/Demul/memsaves/vms00.bin")
		on_stop(memory_card)
	}
}

func init() {
	BUTTON_CODE_MAP = map[string]int64 {
		"button_12" : 805306368, // up
		"button_13" : 805306369, // down
		"button_14" : 805306370, // left
		"button_15" : 805306371, // right
		"button_9" : 805306372, // start
		"button_0" : 805306380, // A
		"button_1" : 805306381, // B
		"button_2" : 805306382, // X
		"button_3" : 805306383, // Y
		"button_7" : 1342177280, // L Trigger
		"button_6" : 1342177536, // R Trigger
		"axes_0-" : -1879048192, // L Stick Left
		"axes_0+" : -1879047936, // L Stick Right
		"axes_1-" : -1879047680, // L Stick Up
		"axes_1+" : -1879047424, // L Stick Down
		"axes_2-" : -1879047168, // R Stick Left
		"axes_2+" : -1879046912, // R Stick Right
		"axes_3-" : -1879046656, // R Stick Up
		"axes_3+" : -1879046400, // R Stick Down
	}
}
