
module WebSocket;

private static void function(string message) g_cb = null;

private extern (C++) void ws_start(int port, void function(char* message, size_t length));

private extern (C++) void ws_write(char *message, size_t length);

private extern (C++) void on_message(char* char_message, size_t length) {
	import std.conv;

	string message = to!string(char_message[0 .. length]);
	g_cb(message);
}

void start(int port, void function(string message) cb) {
	import core.thread;

	new Thread({
		g_cb = cb;
		ws_start(port, &on_message);
	}).start();
}

void write(string message) {
	import std.string;

	char* char_message = cast(char*) toStringz(message);
	ws_write(char_message, message.length+1);
}
