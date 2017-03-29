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


var g_socket = null;

function web_socket_send_data(message) {
	console.log("<<< out ", message["action"], message);
	//console.trace();
	// Convert message to json
	message = JSON.stringify(message);

	// Convert json to base64
	message = btoa(message);

	var header = message.length.toString();
	message = header + ":" + message;
	//console.log("sending message: " + message);

	// Send the message
	g_socket.send(message);
}

function setup_websocket(port, on_data, on_open_cb, on_close_cb) {
	var host = "ws://localhost:" + port.toString() + "/ws";
	g_socket = null;

	try {
		// NOTE: Even though we are catching the exception, this will still print an error in the console
		g_socket = new WebSocket(host);
	} catch(e) {
		g_socket = null;
	}

	// event handlers for websocket
	if(g_socket) {
		g_socket.onopen = function() {
			if(on_open_cb) {
				try {
					on_open_cb();
				} catch(e) {
				}
			}
		};

		g_socket.onmessage = function(msg) {
			// Read the message
			var message =  msg.data;
			//console.log("received message: " + message);

			// Get the length and data
			var chunks = message.split(":");
			var length = chunks[0];
			var data = chunks[1];
			//console.log(data);

			// Convert the data to an object
			data = atob(data);
			data = JSON.parse(data);
			//console.log(data);

			// Convert the actual data to an object
			//console.log(data);
			on_data(data);
		};

		g_socket.onclose = function() {
			reconnect_websocket(port, on_data, on_open_cb, on_close_cb);
		};

		g_socket.onerror = function(err) {
		};
	} else {
		reconnect_websocket(port, on_data, on_open_cb, on_close_cb);
	}
}

function reconnect_websocket(port, on_data, on_open_cb, on_close_cb) {
	console.log("Reconnecting to WebSocket ...");
	// Show the error page after 2 seconds, and start the reconnection loop
	// This prevents the error page from flickering on when we move pages
	setTimeout(function() {
		if(on_close_cb) {
			try {
				on_close_cb();
			} catch(e) {
			}
		}

		// Re-connect again in 2 seconds
		setTimeout(function() {
			setup_websocket(port, on_data, on_open_cb, on_close_cb);
		}, 2000);
	}, 1000);
}
