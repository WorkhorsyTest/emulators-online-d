

module gui;


version (Windows) string DialogDirectorySelect() {
	import win32.winuser : HWND;
	import win32_helpers;

	// Grab the browser window
	HWND hwnd = GetBrowserWindow();

	// If no browser was found, grab the desktop
	if (hwnd == null) {
		hwnd = GetDesktopWindow();
	}

	// Throw an error if none were found
	if (hwnd == null) {
		throw new Exception("Failed to find any Firefox, Chrome, Opera, Edge, Internet Explorer, or the Desktop window to put the Folder Dialog on top of.");
	}

	// Get the directory name from a Directory Dialog Box
	return DialogDirectorySelect(hwnd);
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
