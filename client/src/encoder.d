
import vibe.vibe;
import std.base64;
import std.json;

JSONValue DecodeWebSocketRequest(string buffer) {
	JSONValue j;
	bool is_valid = false;

	try {
		// Get the message length and encoded message
		string[] chunks = buffer.split(":");
		long length = chunks[0].to!long;
		string base64ed_message = chunks[1];

		byte[] jsoned_blob = cast(byte[]) Base64.decode(base64ed_message);
		j = parseJSON(jsoned_blob);
		is_valid = true;
		logInfo(">>> in: %s", j);
	} catch (Throwable err) {

	}

	if (! is_valid) {
		throw new Exception("Failed to decode request.");
	}

	return j;
}

string EncodeWebSocketResponse(JSONValue message) {
	logInfo("<<< out: %s", message);
	//logInfo("message: %s", message);
	ubyte[] response = cast(ubyte[]) "%s".format(message);
	ubyte[] base64ed = cast(ubyte[]) Base64.encode(response);
	string encoded = "%d:%s".format(base64ed.length, cast(string) base64ed);
	//logInfo("Response: %s", encoded);

	return encoded;
}
