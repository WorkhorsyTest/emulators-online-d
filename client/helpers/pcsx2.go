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


package helpers

import(
	"os"
	//"strings"
	//"fmt"
	"io/ioutil"
	//"path/filepath"
)

type PCSX2 struct {
	*BaseConsole
}

func NewPCSX2() *PCSX2 {
	self := &PCSX2{}
	self.BaseConsole = NewBaseConsole("config/pcsx2.json")

	// Setup the initial map, if there is none
	if self.button_map == nil {
		self.button_map = map[string]string {
			"btn_up_pcsx2" : "",
			"btn_down_pcsx2" : "",
			"btn_left_pcsx2" : "",
			"btn_right_pcsx2" : "",
			"btn_start_pcsx2" : "",
			"btn_select_pcsx2" : "",
			"btn_cross_pcsx2" : "",
			"btn_square_pcsx2" : "",
			"btn_circle_pcsx2" : "",
			"btn_triangle_pcsx2" : "",
			"btn_l1_pcsx2" : "",
			"btn_l2_pcsx2" : "",
			"btn_l3_pcsx2" : "",
			"btn_r1_pcsx2" : "",
			"btn_r2_pcsx2" : "",
			"btn_r3_pcsx2" : "",
			"btn_left_stick_up_pcsx2" : "",
			"btn_left_stick_down_pcsx2" : "",
			"btn_left_stick_left_pcsx2" : "",
			"btn_left_stick_right_pcsx2" : "",
			"btn_right_stick_up_pcsx2" : "",
			"btn_right_stick_down_pcsx2" : "",
			"btn_right_stick_left_pcsx2" : "",
			"btn_right_stick_right_pcsx2" : "",
		}
	}

	return self
}

func (self *PCSX2) setupPortable() {
	config := map[string]map[string]interface{} {
		"" : {
			"RunWizard" : "0",
		},
	}
	WriteIniFile("emulators/pcsx2/portable.ini", config)
}

func (self *PCSX2) setupDev9null() {
	config := map[string]map[string]interface{} {
		"" : {
			"logging" : "0",
		},
	}
	WriteIniFile("emulators/pcsx2/inis/Dev9null.ini", config)
}

func (self *PCSX2) setupFWnull() {
	config := map[string]map[string]interface{} {
		"" : {
			"logging" : "0",
		},
	}
	WriteIniFile("emulators/pcsx2/inis/FWnull.ini", config)
}

func (self *PCSX2) setupUSBnull() {
	config := map[string]map[string]interface{} {
		"" : {
			"logging" : "0",
		},
	}
	WriteIniFile("emulators/pcsx2/inis/USBnull.ini", config)
}

func (self *PCSX2) setupSPU2_x() {
	config := map[string]map[string]interface{} {
		"EmuCore" : {
			"CdvdVerboseReads" : "disabled",
			"CdvdDumpBlocks" : "disabled",
			"CdvdShareWrite" : "disabled",
			"EnablePatches" : "enabled",
			"EnableCheats" : "disabled",
			"EnableWideScreenPatches" : "disabled",
			"ConsoleToStdio" : "disabled",
			"HostFs" : "disabled",
			"BackupSavestate" : "enabled",
			"McdEnableEjection" : "enabled",
			"MultitapPort0_Enabled" : "disabled",
			"MultitapPort1_Enabled" : "disabled",
		},
		"EmuCore/Speedhacks" : {
			"EECycleRate" : "0",
			"VUCycleSteal" : "0",
			"fastCDVD" : "disabled",
			"IntcStat" : "enabled",
			"WaitLoop" : "enabled",
			"vuFlagHack" : "enabled",
			"vuThread" : "disabled",
		},
		"EmuCore/CPU" : {
			"FPU.DenormalsAreZero" : "enabled",
			"FPU.FlushToZero" : "enabled",
			"FPU.Roundmode" : "3",
			"VU.DenormalsAreZero" : "enabled",
			"VU.FlushToZero" : "enabled",
			"VU.Roundmode" : "3",
		},
		"EmuCore/CPU/Recompiler" : {
			"EnableEE" : "enabled",
			"EnableIOP" : "enabled",
			"EnableEECache" : "disabled",
			"EnableVU0" : "enabled",
			"EnableVU1" : "enabled",
			"UseMicroVU0" : "enabled",
			"UseMicroVU1" : "enabled",
			"vuOverflow" : "enabled",
			"vuExtraOverflow" : "disabled",
			"vuSignOverflow" : "disabled",
			"vuUnderflow" : "disabled",
			"fpuOverflow" : "enabled",
			"fpuExtraOverflow" : "disabled",
			"fpuFullMode" : "disabled",
			"StackFrameChecks" : "disabled",
			"PreBlockCheckEE" : "disabled",
			"PreBlockCheckIOP" : "disabled",
		},
		"EmuCore/GS" : {
			"SynchronousMTGS" : "disabled",
			"DisableOutput" : "disabled",
			"VsyncQueueSize" : "2",
			"FrameLimitEnable" : "enabled",
			"FrameSkipEnable" : "disabled",
			"VsyncEnable" : "disabled",
			"LimitScalar" : "1.00",
			"FramerateNTSC" : "59.94",
			"FrameratePAL" : "50.00",
			"DefaultRegionMode" : "ntsc",
			"FramesToDraw" : "2",
			"FramesToSkip" : "2",
		},
		"EmuCore/Gamefixes" : {
			"VuAddSubHack" : "disabled",
			"VuClipFlagHack" : "disabled",
			"FpuCompareHack" : "disabled",
			"FpuMulHack" : "disabled",
			"FpuNegDivHack" : "disabled",
			"XgKickHack" : "disabled",
			"IPUWaitHack" : "disabled",
			"EETimingHack" : "disabled",
			"SkipMPEGHack" : "disabled",
			"OPHFlagHack" : "disabled",
			"DMABusyHack" : "disabled",
			"VIFFIFOHack" : "disabled",
			"VIF1StallHack" : "disabled",
			"GIFReverseHack" : "disabled",
			"FMVinSoftwareHack" : "disabled",
			"GoemonTlbHack" : "disabled",
		},
		"EmuCore/Profiler" : {
			"Enabled" : "disabled",
			"RecBlocks_EE" : "enabled",
			"RecBlocks_IOP" : "enabled",
			"RecBlocks_VU0" : "enabled",
			"RecBlocks_VU1" : "enabled",
		},
		"EmuCore/Debugger" : {
			"ShowDebuggerOnStart" : "disabled",
			"FontWidth" : "8",
			"FontHeight" : "12",
		},
		"EmuCore/TraceLog" : {
			"Enabled" : "disabled",
			"EE.bitset" : "0",
			"IOP.bitset" : "0",
		},
	}
	WriteIniFile("emulators/pcsx2/inis/PCSX2_vm.ini", config)
}

func (self *PCSX2) setupPCSX2_vm() {
	config := map[string]map[string]interface{} {
		"MIXING" : {
			"Interpolation" : "4",
			"Disable_Effects" : "FALSE",
			"DealiasFilter" : "FALSE",
			"FinalVolume" : "100",
			"AdvancedVolumeControl" : "FALSE",
			"VolumeAdjustC(dB)" : "0.000000",
			"VolumeAdjustFL(dB)" : "0.000000",
			"VolumeAdjustFR(dB)" : "0.000000",
			"VolumeAdjustBL(dB)" : "0.000000",
			"VolumeAdjustBR(dB)" : "0.000000",
			"VolumeAdjustSL(dB)" : "0.000000",
			"VolumeAdjustSR(dB)" : "0.000000",
			"VolumeAdjustLFE(dB)" : "0.000000",
		},
		"OUTPUT" : {
			"Synch_Mode" : "0",
			"SpeakerConfiguration" : "0",
			"DplDecodingLevel" : "0",
			"Latency" : "100",
			"Output_Module" : "xaudio2",
		},
		"DSP PLUGIN" : {
			"Filename" : "",
			"ModuleNum" : "0",
			"Enabled" : "FALSE",
		},
		"WAVEOUT" : {
			"Device" : "default",
			"Buffer_Count" : "4",
		},
		"DSOUNDOUT" : {
			"Device" : "default",
			"Buffer_Count" : "5",
			"Disable_Global_Focus" : "FALSE",
			"Use_Hardware" : "FALSE",
		},
		"PORTAUDIO" : {
			"HostApi" : "WASAPI",
			"Device" : "default",
			"Wasapi_Exclusive_Mode" : "FALSE",
			"Minimal_Suggested_Latency" : "TRUE",
			"Manual_Suggested_Latency_MS" : "20",
		},
		"SOUNDTOUCH" : {
			"SequenceLengthMS" : "30",
			"SeekWindowMS" : "20",
			"OverlapMS" : "10",
		},
		"DEBUG" : {
			"Global_Enable" : "FALSE",
			"Show_Messages" : "FALSE",
			"Show_Messages_Key_On_Off" : "FALSE",
			"Show_Messages_Voice_Off" : "FALSE",
			"Show_Messages_DMA_Transfer" : "FALSE",
			"Show_Messages_AutoDMA" : "FALSE",
			"Show_Messages_Overruns" : "FALSE",
			"Show_Messages_CacheStats" : "FALSE",
			"Log_Register_Access" : "FALSE",
			"Log_DMA_Transfers" : "FALSE",
			"Log_WAVE_Output" : "FALSE",
			"Dump_Info" : "FALSE",
			"Dump_Memory" : "FALSE",
			"Dump_Regs" : "FALSE",
			"Visual_Debug_Enabled" : "FALSE",
			"Logs_Folder" : "logs",
			"Dumps_Folder" : "logs",
			"Access_Log_Filename" : "SPU2Log.txt",
			"DMA4Log_Filename" : "SPU2dma4.dat",
			"DMA7Log_Filename" : "SPU2dma7.dat",
			"Info_Dump_Filename" : "SPU2Cores.txt",
			"Mem_Dump_Filename" : "SPU2mem.dat",
			"Reg_Dump_Filename" : "SPU2regs.dat",
		},
	}
	WriteIniFile("emulators/pcsx2/inis/SPU2-X.ini", config)
}

func (self *PCSX2) setupPCSX2_ui(bios_file_name string) {
	config := map[string]map[string]interface{} {
		"" : {
			"MainGuiPosition" : "0,0",
			"SysSettingsTabName" : "Cpu",
			"McdSettingsTabName" : "none",
			"ComponentsTabName" : "Plugins",
			"AppSettingsTabName" : "Appearance",
			"GameDatabaseTabName" : "none",
			"LanguageId" : "0",
			"LanguageCode" : "default",
			"RecentIsoCount" : "12",
			"GzipIsoIndexTemplate" : "$(f).pindex.tmp",
			"DeskTheme" : "default",
			"Listbook_ImageSize" : "32",
			"Toolbar_ImageSize" : "24",
			"Toolbar_ShowLabels" : "enabled",
			"CurrentIso" : "E:\\Sony\\Playstation2\\Ace Combat Zero - The Belkan War (USA)\\Ace Combat Zero - The Belkan War (USA).iso",
			"CurrentELF" : "",
			"EnableSpeedHacks" : "enabled",
			"EnableGameFixes" : "disabled",
			"EnablePresets" : "enabled",
			"PresetIndex" : "1",
			"McdCompressNTFS" : "enabled",
			"CdvdSource" : "Iso",
		},
		"MemoryCards" : {
			"Slot1_Enable" : "enabled",
			"Slot1_Filename" : "Mcd001.ps2",
			"Slot2_Enable" : "enabled",
			"Slot2_Filename" : "Mcd002.ps2",
			"Multitap1_Slot2_Enable" : "disabled",
			"Multitap1_Slot2_Filename" : "Mcd-Multitap1-Slot02.ps2",
			"Multitap1_Slot3_Enable" : "disabled",
			"Multitap1_Slot3_Filename" : "Mcd-Multitap1-Slot03.ps2",
			"Multitap1_Slot4_Enable" : "disabled",
			"Multitap1_Slot4_Filename" : "Mcd-Multitap1-Slot04.ps2",
			"Multitap2_Slot2_Enable" : "disabled",
			"Multitap2_Slot2_Filename" : "Mcd-Multitap2-Slot02.ps2",
			"Multitap2_Slot3_Enable" : "disabled",
			"Multitap2_Slot3_Filename" : "Mcd-Multitap2-Slot03.ps2",
			"Multitap2_Slot4_Enable" : "disabled",
			"Multitap2_Slot4_Filename" : "Mcd-Multitap2-Slot04.ps2",
		},
		"ProgramLog" : {
			"Visible" : "enabled",
			"AutoDock" : "enabled",
			"DisplayPosition" : "0,0",
			"DisplaySize" : "680,560",
			"FontSize" : "8",
			"Theme" : "Default",
		},
		"Folders" : {
			"UseDefaultBios" : "enabled",
			"UseDefaultSnapshots" : "enabled",
			"UseDefaultSavestates" : "enabled",
			"UseDefaultMemoryCards" : "enabled",
			"UseDefaultLogs" : "enabled",
			"UseDefaultLangs" : "enabled",
			"UseDefaultPluginsFolder" : "enabled",
			"UseDefaultCheats" : "enabled",
			"UseDefaultCheatsWS" : "enabled",
			"Bios" : "bios",
			"Snapshots" : "snaps",
			"Savestates" : "sstates",
			"MemoryCards" : "memcards",
			"Logs" : "logs",
			"Langs" : "Langs",
			"Cheats" : "cheats",
			"CheatsWS" : "cheats_ws",
			"PluginsFolder" : "plugins",
			"RunIso" : "",
			"RunELF" : "",
		},
		"Filenames" : {
			"GS" : "GSdx32-SSE2.dll",
			"PAD" : "LilyPad.dll",
			"SPU2" : "SPU2-X.dll",
			"CDVD" : "cdvdGigaherz.dll",
			"USB" : "USBnull.dll",
			"FW" : "FWnull.dll",
			"DEV9" : "DEV9null.dll",
			"BIOS" : bios_file_name,
		},
		"GSWindow" : {
			"CloseOnEsc" : "enabled",
			"DefaultToFullscreen" : "disabled",
			"AlwaysHideMouse" : "disabled",
			"DisableResizeBorders" : "disabled",
			"DisableScreenSaver" : "enabled",
			"WindowSize" : "640,480",
			"WindowPos" : "78,78",
			"IsMaximized" : "disabled",
			"IsFullscreen" : "disabled",
			"IsToggleFullscreenOnDoubleClick" : "enabled",
			"AspectRatio" : "4:3",
			"Zoom" : "100.00",
		},
		"Framerate" : {
			"NominalScalar" : "1.00",
			"TurboScalar" : "2.00",
			"SlomoScalar" : "0.50",
			"SkipOnLimit" : "disabled",
			"SkipOnTurbo" : "disabled",
		},
		"ConsoleLogSources" : {
			"Devel" : "disabled",
			".EEout" : "enabled",
			".IOPout" : "enabled",
			".EErecPerf" : "disabled",
			".ELF" : "disabled",
			".SysEvents" : "disabled",
			".pxThread" : "disabled",
		},
		"TraceLogSources" : {
			".SIF" : "disabled",
			"EE.Bios" : "disabled",
			"EE.Memory" : "disabled",
			"EE.Disasm.R5900" : "disabled",
			"EE.Disasm.COP0" : "disabled",
			"EE.Disasm.FPU" : "disabled",
			"EE.Disasm.VUmacro" : "disabled",
			"EE.Disasm.Cache" : "disabled",
			"EE.Registers.HwRegs" : "disabled",
			"EE.Registers.UnknownRegs" : "disabled",
			"EE.Registers.DmaRegs" : "disabled",
			"EE.Registers.IPU" : "disabled",
			"EE.GIFtags" : "disabled",
			"EE.VIFcodes" : "disabled",
			"EE.MSKPATH3" : "disabled",
			"EE.Events.DmaCtrl" : "disabled",
			"EE.Events.Counters" : "disabled",
			"EE.Events.MFIFO" : "disabled",
			"EE.Events.VIF" : "disabled",
			"EE.Events.GIF" : "disabled",
			"IOP.Bios" : "disabled",
			"IOP.Memorycards" : "disabled",
			"IOP.Pad" : "disabled",
			"IOP.Disasm.R3000A" : "disabled",
			"IOP.Disasm.Memory" : "disabled",
			"IOP.Registers.HwRegs" : "disabled",
			"IOP.Registers.UnknownRegs" : "disabled",
			"IOP.Registers.DmaRegs" : "disabled",
			"IOP.Events.DmaCrl" : "disabled",
			"IOP.Events.Counters" : "disabled",
			"IOP.Events.CDVD" : "disabled",
		},
		"TraceLogSources/IOP.Disasm.COP2" : {
			"GPU" : "disabled",
		},
	}
	WriteIniFile("emulators/pcsx2/inis/PCSX2_ui.ini", config)
}


func (self *PCSX2) Run(path string, binary string) {
	// Figure out if running a game or not
	full_screen := false
	if binary != "" {
		full_screen = true
	} else {
		full_screen = false
	}

	// Find the default bios
	var bios_file_name string
	if IsFile("emulators/pcsx2/bios/default_bios") {
		data, err := ioutil.ReadFile("emulators/pcsx2/bios/default_bios")
		if err != nil {
			panic(err)
		}
		bios_file_name = string(data)
	}

	// Setup ini files
	if ! IsDir("emulators/pcsx2/inis") {
		os.Mkdir("emulators/pcsx2/inis", os.ModeDir)
	}
	self.setupPortable()
	self.setupDev9null()
	self.setupFWnull()
	self.setupUSBnull()
	self.setupPCSX2_vm()
	self.setupSPU2_x()
	self.setupPCSX2_ui(bios_file_name)

	os.Chdir("emulators/pcsx2/")
	command := CommandWithArgs {
		"pcsx2.exe",
		[]string {"--nogui", binary},
	}

	// Run the game
	var runner EmuRunner
	full_screen_alt_enter := true
	runner.Setup(command, "GSdx", full_screen, full_screen_alt_enter)
	runner.Run()
	os.Chdir("../..")
}
