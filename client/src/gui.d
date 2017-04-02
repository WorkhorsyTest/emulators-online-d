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


module gui;


version (Windows) string DialogDirectorySelect() {
	static import win32.winuser;
	static import win32_helpers;

	// Grab the browser window
	win32.winuser.HWND hwnd = win32_helpers.GetBrowserWindow();

	// If no browser was found, grab the desktop
	if (hwnd == null) {
		hwnd = win32.winuser.GetDesktopWindow();
	}

	// Throw an error if none were found
	if (hwnd == null) {
		throw new Exception("Failed to find any Firefox, Chrome, Opera, Edge, Internet Explorer, or the Desktop window to put the Folder Dialog on top of.");
	}

	// Get the directory name from a Directory Dialog Box
	return win32_helpers.DialogDirectorySelect(hwnd);
}

version (linux) string DialogDirectorySelect() {
	import std.process;
	import std.algorithm;
	import std.array;

	const string[] command = [
		"zenity",
		"--title=\"Select game directory\"",
		"--file-selection",
		"--directory",
	];

	// Run the command and wait for it to complete
	auto pipes = pipeProcess(command, Redirect.stdout | Redirect.stderr);
	int status = wait(pipes.pid);
	string[] result_stdout = pipes.stdout.byLine.map!(l => l.idup).array();
	string[] result_stderr = pipes.stderr.byLine.map!(l => l.idup).array();
	string target_directory = result_stdout.join("");

	if (status != 0) {
		throw new Exception("Failed to run zenity.");
	}

	return target_directory;
}
