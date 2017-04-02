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


module worker;

import std.concurrency;
static import vibe.vibe;
import std.stdio;
import std.json;
import encoder;


void Send(Tid tid, string message) {
	send(tid, message);
}

Tid Start() {
	Tid tid = spawn(&backgroundThread, thisTid);

	auto val = vibe.vibe.async({
		run();
		return 0;
	});

	return tid;
}

private void run() {
	import core.time;

	while (true) {
		receiveTimeout(1.seconds,
			(string m) { vibe.vibe.logInfo("FIXME: Got message:%s", m); },
			(Variant v) { vibe.vibe.logWarn("Received some other type."); }
		);
	}
}

private void backgroundThread(Tid ownerTid) {
	while (true) {
		receive((string msg) {
			JSONValue message_map;
			message_map = DecodeMessage(msg);
			string action = message_map["action"].str;
			switch (action) {
				case "search_game_directory":
					string console = message_map["console"].str;
					string dir_name = message_map["directory_name"].str;
					vibe.vibe.logInfo("FIXME: start searching the directory %s", dir_name);
					break;
				default:
					break;
			}
		});
	}

	//string response = "FIXME: the response goes here";
	//send(ownerTid, response);
}
