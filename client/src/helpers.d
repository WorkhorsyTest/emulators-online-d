

module helpers;

import std.stdio;

int g_direct_x_version = -1;

void TryRemovingFileOnExit(string file_name) {
	import std.file;

	if (std.file.exists(file_name)) {
		try {
			std.file.remove(file_name);
		} catch (FileException err) {
			// Ignore any error
		}
	}
};

int GetDirectxVersion() {
	int int_version = -1;

	version (Windows) {
		import std.process;
		import std.file;
		import std.stdio;
		import std.string;

		// Try to remove any generated files when the function exists
		scope (exit) TryRemovingFileOnExit("directx_info.txt");

		const string[] command = [
			"dxdiag.exe",
			"/t",
			"directx_info.txt",
		];

		// Run the command and wait for it to complete
		auto pipes = pipeProcess(command, Redirect.stdout | Redirect.stderr);
		int status = wait(pipes.pid);

		if (status != 0) {
			stderr.writefln("Failed to determine DirectX version"); stderr.flush();
		}

		string string_data = cast(string) std.file.read("directx_info.txt");
		string raw_version = string_data.split("DirectX Version: ")[1].split("\r\n")[0];

		// Get the DirectX version
		if (raw_version.indexOf("12") != -1) {
			int_version = 12;
		} else if (raw_version.indexOf("11") != -1) {
			int_version = 11;
		} else if (raw_version.indexOf("10") != -1) {
			int_version = 10;
		} else if (raw_version.indexOf("9") != -1) {
			int_version = 9;
		} else {
			stderr.writefln("Failed to determine DirectX version"); stderr.flush();
		}
	}

	return int_version;
}
