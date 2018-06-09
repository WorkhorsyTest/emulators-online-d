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

import vibe.vibe : logInfo;
import std.json : JSONValue;


JSONValue DecodeMessage(string buffer) {
	import std.base64 : Base64;
	import std.json : JSONValue, parseJSON;
	import std.string : split;
	import std.conv : to;

	JSONValue j;
	bool is_valid = false;

	try {
		// Get the message length and encoded message
		string[] chunks = buffer.split(":");
		long length = chunks[0].to!long;
		string base64ed_message = chunks[1];

		byte[] jsoned_blob = cast(byte[]) Base64.decode(base64ed_message);
		j = parseJSON(cast(char[])jsoned_blob);
		is_valid = true;
		logInfo(">>> in: %s", j);
	} catch (Throwable err) {

	}

	if (! is_valid) {
		throw new Exception("Failed to decode request.");
	}

	return j;
}

string EncodeMessage(JSONValue message) {
	import std.base64 : Base64;
	import std.string : format;

	logInfo("<<< out: %s", message);
	//logInfo("message: %s", message);
	ubyte[] response = cast(ubyte[]) "%s".format(message);
	ubyte[] base64ed = cast(ubyte[]) Base64.encode(response);
	string encoded = "%d:%s".format(base64ed.length, cast(string) base64ed);
	//logInfo("Response: %s", encoded);

	return encoded;
}
