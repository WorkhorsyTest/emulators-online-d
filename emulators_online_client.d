

import std.stdio;
import core.thread;
import WebSocket;


int main() {
	WebSocket.start(9090, function(string message) {
		stdout.writefln("message:\"%s\"", message);
	});

	Thread.sleep(10.seconds);
	while (true) {
		string message = "12345";
		//stdout.writefln(message);
		WebSocket.write(message);
		Thread.sleep(2.seconds);
	}

	return 0;
}
