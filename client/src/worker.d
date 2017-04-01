
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
