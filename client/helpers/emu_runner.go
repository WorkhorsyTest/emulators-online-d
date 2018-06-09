// Copyright (c) 2015-2018 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
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
	"os/exec"
	"bytes"
	"fmt"
	"time"
	"../win32"
)

type CommandWithArgs struct {
	name string
	args []string
}

type EmuRunner struct {
	emu_title_bar_text string
	command CommandWithArgs
	full_screen bool
	full_screen_alt_enter bool
	emu_proc *exec.Cmd
}

func (self *EmuRunner) Setup(command CommandWithArgs, emu_title_bar_text string, full_screen bool, full_screen_alt_enter bool) {
	self.emu_title_bar_text = emu_title_bar_text
	self.command = command
	self.full_screen = full_screen
	self.full_screen_alt_enter = full_screen_alt_enter
	//self.emu_proc = nil
}

func (self *EmuRunner) Run() {
	// 1/10th of a second
	wait_time := time.Millisecond * 100.0

	// Start the program
	self.emu_proc = exec.Command(self.command.name, self.command.args...)
	var std_out bytes.Buffer
	var std_err bytes.Buffer
	self.emu_proc.Stdout = &std_out
	self.emu_proc.Stderr = &std_err
	err := self.emu_proc.Start()
	if err != nil {
		fmt.Printf("Failed to start running the command: %s\r\n", err)
		panic(err)
	}

	// Wait for the program's window to actually be created
	var hwnd win32.HWND
	var title string
	time.Sleep(wait_time)
	for {
		fmt.Printf("Waiting for emulator window to appear ...\r\n")
		// Look through all the windows and find the one with the title bar text we want
		hwnd, title = win32.FindWindowWithTitleText(self.emu_title_bar_text)

		// Sleep for a bit if the window was not found
		if title == "" {
			time.Sleep(time.Second)
		} else {
			break
		}
	}

	// Show the window if it is minimized
	time.Sleep(wait_time)
	win32.ShowWindow(hwnd, true)
	win32.SetWindowPos(hwnd, win32.HWND_TOPMOST, 0, 0, 0,0, win32.SWP_NOMOVE | win32.SWP_NOSIZE)
	win32.SetWindowPos(hwnd, win32.HWND_NOTOPMOST, 0, 0, 0,0, win32.SWP_NOMOVE | win32.SWP_NOSIZE)
	win32.SetActiveWindow(hwnd)
	//win32.SetForegroundWindow(hwnd)

	// Move the mouse to the window corner, click on it, and move the mouse to the corner
	time.Sleep(wait_time)
	rect := win32.GetWindowRect(hwnd)
	win32.SetCursorPos(rect.Left + 1, rect.Top + 1)
	win32.MouseEvent(win32.MOUSEEVENTF_LEFTDOWN, rect.Left, rect.Top, 0, 0)
	win32.MouseEvent(win32.MOUSEEVENTF_LEFTUP, rect.Left, rect.Top, 0, 0)
	win32.SetCursorPos(0, 0)

	// Fullscreening the emu window with alt + enter if needed
	if self.full_screen && self.full_screen_alt_enter {
		time.Sleep(wait_time)
		win32.KeybdEvent(win32.VK_MENU, 0, 0, 0)
		win32.KeybdEvent(win32.VK_RETURN, 0, 0, 0)
		time.Sleep(time.Second * 2)
		win32.KeybdEvent(win32.VK_RETURN, 0, win32.KEYEVENTF_KEYUP, 0)
		win32.KeybdEvent(win32.VK_MENU, 0, win32.KEYEVENTF_KEYUP, 0)
	}
}

func (self *EmuRunner) Stop() string {
	//output := self.emu_proc.stdout.read()
	return "FIXME: Read the program output here"
}
