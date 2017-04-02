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


var g_is_web_socket_setup = false;
var g_is_game_db_downloaded = false;
var g_button_map_demul = {};

var g_is_linux = false;
var g_is_directx_end_user_runtime_installed = false;
var g_is_vcpp_2010_redist_installed = false;
var g_is_vcpp_2013_redist_installed = false;
var g_is_demul_installed = false;
var g_is_pcsx2_installed = false;
var g_directx_version = 10;

var g_db = {};
var g_user_id = null;
var g_is_localhost = (["127.0.0.1", "localhost"].indexOf(document.location.hostname.toLowerCase()) != -1);

function assert_os_and_browser_requirements() {
	var errors = [];

	// Get the user agent
	var agent = navigator.userAgent.toLowerCase();

	// Show an alert if not on a good browser
	if (agent.indexOf('firefox') == -1 && agent.indexOf('chrome') == -1) {
		errors.push('It only works in Firefox, Chrome, Opera or Edge browsers.');
	}

	// Check for localStorage
	if (!("localStorage" in window)) {
		errors.push("Your browser does not support localStorage.");
	}

	// Check for WebSockets
	// NOTE: IE 11 says it supports WebSockets, but it does not follow the specification
	if (!("WebSocket" in window) || agent.indexOf('trident') != -1) {
		errors.push("Your browser does not support WebSockets.");
	}

	// Check for Gamepads
	if (!("getGamepads" in navigator)) {
		errors.push("Your browser does not support Gamepads.");
	}

	// Show an error message it features are missing
	if (errors.length) {
		var error_message = "This application will not run correctly!\r\n";
		for(var i=0; i<errors.length; ++i) {
			error_message += i+1 + ". " + errors[i] + "\r\n";
		}
		alert(error_message);
	}
}

function setup_user_id() {
	// Generate a random user id and store it in localStorage
	if (localStorage.getItem("g_user_id") == null) {
		g_user_id = generate_random_user_id();
		localStorage.setItem("g_user_id", g_user_id);
	// Or return the user id if already there
	} else {
		g_user_id = localStorage.getItem("g_user_id");
	}
	console.log("g_user_id: " + g_user_id);
}

function generate_random_user_id() {
	// Get a 20 character user id
	var code_table = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	var user_id = "";
	for (var i = 0; i < 20; ++i) {
		// Get a random number between 0 and 35
		var num = Math.floor((Math.random() * 36));

		// Get the character that corresponds to the number
		user_id += code_table[num];
	}

	return user_id;
}

// FIXME: The way we construct these divs dynamically is terrible. Replace with templates.
function make_game_icon(console_name, name, data, i) {
	// Create the icon
	var text = "" +
			"<a href=\"#dialog_" + name + "\" id=\"preview_" + console_name + "_" + i + "\">";

	if(data["binary"])
		text += "<img src=\"" + data["path"] + "title_small.png\" />";

	text += "<br />" +
		name + "</a>";

	var d = document.createElement('div');
	d.className = "game_icon";
	d.innerHTML = text;
	document.getElementById('game_selector').appendChild(d);

	var btn = $("#preview_" + console_name + "_" + i);
	btn.off('click');
	btn.on('click', function() {
		// Create the dialog
		var text = "" +
		"<div>" +
		"	<a href=\"#close_game_dialog\" class=\"close_game_dialog\">X</a>" +
		"	<h2>" + name + "</h2>" +
		"	<img src=\"" + data["path"] + "title_big.png\" />" +
		"	<input id=\"btn_" + console_name + "_" + i + "\" type=\"button\" value=\"play\" \>" +
		"	<br />";

		$.each(data["images"], function(n, image) {
			console.log(image);
			if(n != 0)
				text += "	<img src=\"" + image + "\" />";
		});

		text += "</div>";

		var d = document.createElement('div');
		d.id = "dialog_" + name;
		d.className = "game_dialog";
		d.innerHTML = text;
		document.getElementById('game_dialogs').innerHTML = "";
		document.getElementById('game_dialogs').appendChild(d);


		// Have the dialog play button launch the game
		var btn = $("#btn_" + console_name + "_" + i);
		btn.off('click');
		btn.on('click', function() {
			var message = {
				'action' : 'play',
				'name' : name,
				'path' : data['path'],
				'binary' : data['binary'],
				'console' : console_name,
				'bios' : data['bios']
			}
			web_socket_send_data(message);
		});
	});
}

function get_searchable_words(search_string) {
	// Get all the words in the name that are at least 3 characters long
	var all_words = search_string.toLowerCase().match(/\S+/g);
	var search_words = [];
	$.each(all_words, function(i, word) {
		if(word.length > 2) {
			search_words.push(word.toLowerCase());
		}
	});

	return search_words;
}

function on_search(evt) {
	var search_text = $('#search_text');

	// Clear the old icons
	document.getElementById('game_selector').innerHTML = "";

	// If there are no games, tell the user to add some
	var total_games = 0;
	$.each(g_db, function(console_name, console_data) {
		total_games += Object.keys(console_data).length;
	});
	if(total_games == 0) {
		document.getElementById('game_selector').innerHTML = "<h2>There are no games. You can add games on the configure page.</h2>";
		return;
	}

	// Get the words to search for
	var search_raw = search_text.val();
///*
	// Skip empty searches
	if(search_raw.length == 0) {
		var i = 0;
		var console_names = Object.keys(g_db);
		console_names.sort();
		$.each(console_names, function(i, console_name) {
			// Skip empty consoles
			var console_data = g_db[console_name];
			if(Object.keys(console_data).length == 0) {
				return true;
			}

			// Add console name as header
			var d = document.createElement('h1');
			d.innerHTML = console_name;
			d.style.clear = "both";
			document.getElementById('game_selector').appendChild(d);

			//if(console_data != null) {
				var names = $.map(console_data, function(key, value) {return value;});
				names.sort();
				$.each(names, function(j, name) {
					var data = console_data[name];
					make_game_icon(console_name, name, data, i);
					++i;
				});
			//}
		});
		return;
	}
//*/
///*
	// Match game developer
	var match_developer_db = [];
	var lower_search = search_raw.toLowerCase();
	var console_names = Object.keys(g_db);
	console_names.sort();
	$.each(console_names, function(i, console_name) {
		// Skip empty consoles
		var console_data = g_db[console_name];
		if(Object.keys(console_data).length == 0) {
			return true;
		}

		var names = $.map(console_data, function(key, value) {return value;});
		names.sort();
		$.each(names, function(j, name) {
			var data = console_data[name];
			if('developer' in data && data['developer'] && data['developer'].toLowerCase() == lower_search) {
				//console.log(name + " : " + data['developer']);
				match_developer_db.push(name);
			}
		});
	});
//*/
///*
	// Match game publisher
	var match_publisher_db = [];
	var lower_search = search_raw.toLowerCase();
	var console_names = Object.keys(g_db);
	console_names.sort();
	$.each(console_names, function(i, console_name) {
		// Skip empty consoles
		var console_data = g_db[console_name];
		if(Object.keys(console_data).length == 0) {
			return true;
		}

		var names = $.map(console_data, function(key, value) {return value;});
		names.sort();
		$.each(names, function(j, name) {
			var data = console_data[name];
			if('developer' in data && data['developer'] && data['developer'].toLowerCase() == lower_search) {
				match_publisher_db.push(name);
			}
		});
	});
//*/
///*
	// Match game genre
	var match_genre_db = [];
	var lower_search = search_raw.toLowerCase();
	var console_names = Object.keys(g_db);
	console_names.sort();
	$.each(console_names, function(i, console_name) {
		// Skip empty consoles
		var console_data = g_db[console_name];
		if(Object.keys(console_data).length == 0) {
			return true;
		}

		var names = $.map(console_data, function(key, value) {return value;});
		names.sort();
		$.each(names, function(j, name) {
			var data = console_data[name];
			if('genre' in data && data['genre'] && data['genre'].toLowerCase() == lower_search) {
				//console.log(name + " : " + data['genre']);
				match_genre_db.push(name);
			}
		});
	});
//*/
///*
	// Match whole game name
	var match_whole_db = [];
	var lower_search = search_raw.toLowerCase();
	var console_names = Object.keys(g_db);
	console_names.sort();
	$.each(console_names, function(i, console_name) {
		// Skip empty consoles
		var console_data = g_db[console_name];
		if(Object.keys(console_data).length == 0) {
			return true;
		}

		var names = $.map(console_data, function(key, value) {return value;});
		names.sort();
		$.each(names, function(j, name) {
			var data = console_data[name];
			if(name.toLowerCase() == lower_search) {
				match_whole_db.push(name);
			}
		});
	});
//*/
///*
	// Match some words in game name
	var match_words_db = {};
	var search_words = get_searchable_words(search_raw);

	var console_names = Object.keys(g_db);
	console_names.sort();
	$.each(console_names, function(i, console_name) {
		// Skip empty consoles
		var console_data = g_db[console_name];
		if(Object.keys(console_data).length == 0) {
			return true;
		}

		var names = $.map(console_data, function(key, value) {return value;});
		names.sort();
		$.each(names, function(j, name) {
			var data = console_data[name];
			var game_words = get_searchable_words(name);

			// Count how many words match the search
			var match_count = 0;
			$.each(search_words, function(k, search_word) {
				$.each(game_words, function(l, game_word) {
					if(game_word == search_word) {
						++match_count;
					}
				});
			});
			if(match_count > 0) {
				// Init the hash if empty
				if(!(name in match_words_db))
					match_words_db[name] = 0;

				// Save the match count if bigger
				if(match_count > match_words_db[name])
					match_words_db[name] = match_count;
			}
		});
	});
//*/
///*
	// Match parts of words in game name
	var match_parts_db = {};
	var search_words = get_searchable_words(search_raw);

	var console_names = Object.keys(g_db);
	console_names.sort();
	$.each(console_names, function(i, console_name) {
		// Skip empty consoles
		var console_data = g_db[console_name];
		if(Object.keys(console_data).length == 0) {
			return true;
		}

		var names = $.map(console_data, function(key, value) {return value;});
		names.sort();
		$.each(names, function(j, name) {
			var data = console_data[name];
			var game_words = get_searchable_words(name);

			// Count how many words match the search
			var match_count = 0;
			$.each(search_words, function(k, search_word) {
				$.each(game_words, function(l, game_word) {
					if(search_word.indexOf(game_word) > -1 || game_word.indexOf(search_word) > -1) {
						++match_count;
					}
				});
			});
			if(match_count > 0) {
				// Init the hash if empty
				if(!(name in match_parts_db))
					match_parts_db[name] = 0;

				// Save the match count if bigger
				if(match_count > match_parts_db[name])
					match_parts_db[name] = match_count;
			}
		});
	});
//*/

	// Create new icons from the search
	var i = 0;
	var console_names = Object.keys(g_db);
	console_names.sort();
	$.each(console_names, function(i, console_name) {
		// Skip empty consoles
		var console_data = g_db[console_name];
		if(Object.keys(console_data).length == 0) {
			return true;
		}

		var names = $.map(console_data, function(key, value) {return value;});
		names.sort();

		// Add console name as header
		var d = document.createElement('h1');
		d.innerHTML = console_name;
		d.style.clear = "both";
		document.getElementById('game_selector').appendChild(d);

		$.each(names, function(j, name) {
			var is_match = false;
///*
			// Developer matches
			$.each(match_developer_db, function(k, gname) {
				if(name == gname) {
					is_match = true;
					return false;
				}
			});
//*/
///*
			// Publisher matches
			$.each(match_publisher_db, function(k, gname) {
				if(name == gname) {
					is_match = true;
					return false;
				}
			});
//*/
///*
			// Genre matches
			$.each(match_genre_db, function(k, gname) {
				if(name == gname) {
					is_match = true;
					return false;
				}
			});
//*/
///*
			// Whole matches
			$.each(match_whole_db, function(k, gname) {
				if(name == gname) {
					is_match = true;
					return false;
				}
			});
//*/
///*
			// Word matches
			$.each(match_words_db, function(gname, gcount) {
				if(name == gname) {
					is_match = true;
					return false;
				}
			});
//*/
///*
			// Part matches
			$.each(match_parts_db, function(gname, gcount) {
				if(name == gname) {
					is_match = true;
					return false;
				}
			});
//*/
			if(is_match) {
				var data = console_data[name];
				make_game_icon(console_name, name, data, i);
			}

			++i;
		});
	});
}

function browser_set_game_db(value) {
	// Un base64, Un compress, Un array, and Un json the db
	value = atob(value);
	value = pako.inflate(value);
	value = String.fromCharCode.apply(null, value);
	value = JSON.parse(value);

	g_db = value;

	// Show the default search
	on_search();
}

function show_navigation(tab_name) {
	// Hide all the tables
	$('.config_table').hide();

	// Show the selected table
	$('#table_' + tab_name).show();

	// Remove the old selected tab
	$('.selected').addClass('not_selected');
	$('.selected').removeClass('selected');

	// Add the new selected tab
	$('#tab_' + tab_name).removeClass('not_selected');
	$('#tab_' + tab_name).addClass('selected');
}

function show_menu(menu_name) {
	// Hide all the content
	$('.content').hide();

	// Show the selected content
	$('#content_' + menu_name).show();

	// Remove the old selected menu
	$('.menu').addClass('menu_not_selected');
	$('.menu').removeClass('menu_selected');

	// Highlight the current menu
	$('#menu_' + menu_name).removeClass('menu_not_selected');
	$('#menu_' + menu_name).addClass('menu_selected');


	if (menu_name == "configure") {
		show_config_ui();
	} else if (menu_name == "games") {
		if (localStorage.getItem("game_db") != null) {
			$('#empty_game_db').hide();
			var value = localStorage.getItem("game_db");

			browser_set_game_db(value);
		} else {
			$('#empty_game_db').show();
			//browser_set_game_db(value);
		}
	}

	// Only show the search box on the games page
	if (menu_name == "games") {
		$('#search_box').show();
	} else {
		$('#search_box').hide();
	}
}

function show_config_ui() {
	// Show the config, and hide the message to run the client
	$('#install_client').hide();
	$('#config_programs').show();
}

function action_get_directx_version() {
	var message = {
		'action' : 'get_directx_version'
	};
	web_socket_send_data(message);
}

function action_is_linux() {
	var message = {
		'action' : 'is_linux'
	};
	web_socket_send_data(message);
}

function action_is_installed(program_name) {
	var message = {
		'action' : 'is_installed',
		'program' : program_name
	};
	web_socket_send_data(message);
}

function action_install(file_name) {
	var message = {
		'action' : 'install',
		'dir' : 'downloads',
		'file' : file_name
	};
	web_socket_send_data(message);
}

function action_uninstall(program_name) {
	var message = {
		'action' : 'uninstall',
		'name' : program_name
	};
	web_socket_send_data(message);
}

function action_download(file, url, name, referer) {
	var message = {
		'action' : 'download',
		'file' : file,
		'url' : url,
		'dir' : 'downloads',
		'name' : name,
		'referer' : referer
	};
	web_socket_send_data(message);
}

function action_get_button_map(console_name, button_map) {
	var message = {
		'action' : 'get_button_map',
		'console' : console_name,
		'value' : button_map
	};
	web_socket_send_data(message);
}

function action_set_button_map(console_name, button_map) {
	var message = {
		'action' : 'set_button_map',
		'console' : console_name,
		'value' : button_map
	};
	web_socket_send_data(message);
}

function action_set_game_directory(console_name, directory_name) {
	var message = {
		'action' : 'set_game_directory',
		'console' : console_name,
		'directory_name' : directory_name
	};
	web_socket_send_data(message);
}

function action_set_bios(console_name, type_name, file_data, is_default) {
	var message = {
		'action' : 'set_bios',
		'console' : console_name,
		'type' : type_name,
		'is_default' : is_default,
		'value' : btoa(file_data)
	};
	web_socket_send_data(message);
}

function on_websocket_data(data) {
	console.log(">>> in ", data["action"], data);
	//console.trace();

	switch (data['action']) {
	case 'log':
		console.log('Log: ' + data['value']);
		break;
	case 'get_db':
		g_db = data['value'];

		// Show the default search
		on_search();
		break;
	case 'set_db':
		var value = data['value'];

		// Save the game db in localStorage
		localStorage.setItem("game_db", value);

		// Save the game db on the web server
		$.ajax({
			type: "POST",
			url: "http://emulators-online.com/data/index.php",
			dataType: 'json',
			data: {
				action: "set_value",
				id: g_user_id,
				key: "game_db",
				value: value
			}
		})
		.done(function( msg ) {
			console.log("sent game db to web server and localStorage.");
		})
		.fail(function() {
			console.log("sent game db to localStorage.");
		});
		break;
	case 'long_running_tasks':
		var notification_footer = $('#notification_footer');
		notification_footer.empty();
		var long_running_tasks = data['value'];
		if(!$.isEmptyObject(long_running_tasks)) {
			$.each(long_running_tasks, function(task_name, percentage) {
				notification_footer.append("<p>" + task_name + " " + percentage.toFixed(2) + "%</p>");
			});
			notification_footer.css("display", "block");
		} else {
			notification_footer.css("display", "none");
		}
		break;
	case 'get_button_map':
		if(data['console'] == 'dreamcast') {
			g_button_map_demul = data['value'];

			// Setup each button
			$.each(g_button_map_demul, function(key, value) {
				// Get button
				var btn = $('#' + key);

				// Set previous value, if there is one
				if(value) {
					btn.val(value);
				}

				// On click poll for a new button
				btn.click(function() {
					btn.val('Press new button ...');
					btn.prop('disabled', true);
					start_polling_buttons(function(button_name) {
						// Save the new button
						if(button_name == -1) {
							btn.val('Not Assigned');
						} else {
							btn.val(button_name);
							g_button_map_demul[key] = button_name;
						}
						btn.prop('disabled', false);
					});
				});
			});
		}
		break;
	case 'progress':
		if(data['value'] < 100) {
			$('#config_programs').hide();
			$('#generic_progress').text('Downloading ' + data['name'] + ': ' + data['value'] + '%');
			$('#generic_progress').show();
		} else {
			$('#generic_progress').text('');
			$('#generic_progress').hide();
			$('#config_programs').show();
		}
		break;
	case 'uncompress':
		if(data['is_start']) {
			$('#config_programs').hide();
			$('#generic_progress').text('Uncompressing ' + data['name']);
			$('#generic_progress').show();
		} else {
			$('#generic_progress').text('');
			$('#generic_progress').hide();
			$('#config_programs').show();
		}
		break;
	case 'get_directx_version':
		g_directx_version = data['value'];
		$('#select_directx_version').val(g_directx_version);
		break;
	case 'is_linux':
		g_is_linux = data['value'];
		break;
	case 'is_installed':
		if (data['name'] == 'DirectX End User Runtime') {
			g_is_directx_end_user_runtime_installed = data['value'];
		} else if (data['name'] == 'Visual C++ 2010 redist') {
			g_is_vcpp_2010_redist_installed = data['value'];
		} else if (data['name'] == 'Visual C++ 2013 redist') {
			g_is_vcpp_2013_redist_installed = data['value'];
		} else if (data['name'] == 'Demul') {
			g_is_demul_installed = data['value'];
			if ((g_is_directx_end_user_runtime_installed && g_is_vcpp_2010_redist_installed) || g_is_linux) {
				if(g_is_demul_installed) {
					$('#btn_install_demul').val('Uninstall');

					$('#select_directx_version').prop('disabled', false);
					$('#btn_controls_demul').prop('disabled', false);
					$('#btn_dc_folder').prop('disabled', false);
					$('#btn_bios_demul_dc').prop('disabled', false);
					$('#btn_bios_demul_aw').prop('disabled', false);
					$('#btn_bios_demul_naomi').prop('disabled', false);
					$('#btn_bios_demul_naomi2').prop('disabled', false);
				} else {
					$('#btn_install_demul').val('Install');

					$('#select_directx_version').prop('disabled', true);
					$('#btn_controls_demul').prop('disabled', true);
					$('#btn_dc_folder').prop('disabled', true);
					$('#btn_bios_demul_dc').prop('disabled', true);
					$('#btn_bios_demul_aw').prop('disabled', true);
					$('#btn_bios_demul_naomi').prop('disabled', true);
					$('#btn_bios_demul_naomi2').prop('disabled', true);
				}
				$('#btn_install_demul').prop('disabled', false);
				$('#demul_requirements_installed').show();
			}

			if (!g_is_directx_end_user_runtime_installed && ! g_is_linux) {
				$('#demul_directx_end_user_runtime_not_installed').show();
				$('#demul_requirements_installed').hide();
			} else {
				$('#demul_directx_end_user_runtime_not_installed').hide();
			}

			if (!g_is_vcpp_2010_redist_installed && ! g_is_linux) {
				$('#demul_vcpp_2010_redist_not_installed').show();
				$('#demul_requirements_installed').hide();
			} else {
				$('#demul_vcpp_2010_redist_not_installed').hide();
			}
		} else if (data['name'] == 'PCSX2') {
			g_is_pcsx2_installed = data['value'];
			if (g_is_vcpp_2013_redist_installed || g_is_linux) {
				if(g_is_pcsx2_installed) {
					$('#btn_install_pcsx2').val('Uninstall');
					$('#btn_ps2_folder').prop('disabled', false);
					$('#btn_bios_pcsx2_us').prop('disabled', false);
					$('#btn_bios_pcsx2_jp').prop('disabled', false);
					$('#btn_bios_pcsx2_eu').prop('disabled', false);
				} else {
					$('#btn_install_pcsx2').val('Install');
					$('#btn_ps2_folder').prop('disabled', true);
					$('#btn_bios_pcsx2_us').prop('disabled', true);
					$('#btn_bios_pcsx2_jp').prop('disabled', true);
					$('#btn_bios_pcsx2_eu').prop('disabled', true);
				}
				$('#btn_install_pcsx2').prop('disabled', false);
				$('#playstation2_requirements_installed').show();
				$('#playstation2_vcpp_2013_redist_not_installed').hide();
			} else {
				$('#playstation2_requirements_installed').hide();
				$('#playstation2_vcpp_2013_redist_not_installed').show();
			}
		}
		break;
	default:
		console.log('Data: ' + data);
		break;
	}
}

function main() {
	assert_os_and_browser_requirements();
	setup_user_id();

	// Connect to the client on the web socket
	var game_db = null;
	var port = location.port || 9090;
	setup_websocket(port, on_websocket_data, function() {
		$("#error_header").hide();
		g_is_web_socket_setup = true;

		// Get the game database from the emulators-online.com
		// If that fails try loading it from localStorage
		$.ajax({
			type: "POST",
			url: "http://emulators-online.com/data/index.php",
			dataType: 'json',
			data: {
				action: "get_value",
				id: g_user_id,
				key: "game_db"
			}
		})
		.done(function(value) {
			if (value) game_db = value;
			console.log("Loaded game db from http://emulators-online.com");
			g_is_game_db_downloaded = true;
		})
		.fail(function() {
			console.log("Loaded game db from localStorage");
			g_is_game_db_downloaded = true;
		});

		// Figure out if programs are installed
		action_is_linux();
		action_is_installed('DirectX End User Runtime');
		action_is_installed('Visual C++ 2010 redist');
		action_is_installed('Visual C++ 2013 redist');
		action_is_installed('Demul');
		action_is_installed('PCSX2');
		action_get_directx_version();
	}, function() {
		$("#error_header").show();
	});

	// Wait for the game database to be downloaded, and the web socket connection to the client
	var setDbInterval = setInterval(function() {
		// Just return if not ready
		if (!g_is_web_socket_setup || !g_is_game_db_downloaded) {
			return;
		}

		clearInterval(setDbInterval);

		// Send the game database to the client
		message = {
			'action' : 'set_db',
			'value' : game_db
		};
		web_socket_send_data(message);
	}, 300);

	var text = $("#text_user_id");
	text.val(g_user_id);

	var btn = $("#btn_clear_game_db");
	btn.on('click', function() {
		// Remove the game db from js
		g_db = {};

		// Remove the game db from localStorage
		if (localStorage.getItem("game_db") != null) {
			localStorage.removeItem("game_db");
		}
		console.log("Removed game db from the browser's localStorage");

		// Remove the game db from the client
		message = {
			'action' : 'set_db',
			'value' : null
		};
		web_socket_send_data(message);
		console.log("Removed game db from the client");

		// Remove the game db from emulators-online.com
		$.ajax({
			type: "POST",
			url: "http://emulators-online.com/data/index.php",
			dataType: 'json',
			data: {
				action: "set_value",
				id: g_user_id,
				key: "game_db",
				value: null
			}
		})
		.done(function(value) {
			console.log("Removed game db from http://emulators-online.com");
			alert("Cleared the game database.");
		})
		.fail(function() {
			console.log("Failed to remove game db from http://emulators-online.com");
			alert("Cleared the game database.");
		});
	});

	btn = $("#btn_install_demul");
	btn.on('click', function() {
		if(g_is_demul_installed) {
			action_uninstall('Demul');
		} else {
			// Download the compressed program
			action_download('demul0582.rar', 'http://demul.emulation64.com/files/demul0582.rar', 'Demul', '');

			// Uncompress the program
			action_install('demul0582.rar');
		}

		// Figure out if it is installed
		action_is_installed('Demul');
	});

	btn = $("#btn_install_pcsx2");
	btn.on('click', function() {
		if(g_is_pcsx2_installed) {
			action_uninstall('PCSX2');
		} else {
			// Download the compressed program
			action_download('pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z', 'http://buildbot.orphis.net/pcsx2/index.php?m=get&rev=v1.3.1-93-g1aebca3&platform=windows-x86', 'PCSX2', "http://buildbot.orphis.net/pcsx2/index.php?m=detail&rev=v1.3.1-93-g1aebca3&platform=windows-x86");

			// Uncompress the program
			action_install('pcsx2-v1.3.1-93-g1aebca3-windows-x86.7z');
		}

		// Figure out if it is installed
		action_is_installed('PCSX2');
	});

	btn = $('#btn_controls_demul');
	btn.on('click', function() {
		$('#config_buttons_demul').show();
		$('#config_programs').hide();

		// Load the button map
		action_get_button_map('dreamcast', g_button_map_demul);
	});

	btn = $('#btn_dc_folder');
	btn.on('click', function() {
		// Have the server create a win32 folder selection dialog
		var message = {
			'action' : 'set_game_directory',
			'console' : 'dreamcast'
		};
		web_socket_send_data(message);
		console.log('set_game_directory');
	});

	btn = $('#btn_ps2_folder');
	btn.on('click', function() {
		// Have the server create a win32 folder selection dialog
		var message = {
			'action' : 'set_game_directory',
			'console' : 'playstation2'
		};
		web_socket_send_data(message);
		console.log('set_game_directory');
	});

	btn = $('#btn_done_button_config_demul');
	btn.on('click', function() {
		$('#config_buttons_demul').hide();
		$('#config_programs').show();

		// Save the button map
		action_set_button_map('dreamcast', g_button_map_demul);
	});

	FileUploader('btn_bios_pcsx2_us', 'generic_progress', function(file_name, file_data) {
		action_set_bios('playstation2', file_name, file_data, true);
	});

	FileUploader('btn_bios_pcsx2_jp', 'generic_progress', function(file_name, file_data) {
		action_set_bios('playstation2', file_name, file_data, false);
	});

	FileUploader('btn_bios_pcsx2_eu', 'generic_progress', function(file_name, file_data) {
		action_set_bios('playstation2', file_name, file_data, false);
	});

	FileUploader('btn_bios_demul_dc', 'generic_progress', function(file_name, file_data) {
		action_set_bios('dreamcast', 'dc.zip', file_data, false);
	});

	FileUploader('btn_bios_demul_aw', 'generic_progress', function(file_name, file_data) {
		action_set_bios('dreamcast', 'awbios.zip', file_data, false);
	});

	FileUploader('btn_bios_demul_naomi', 'generic_progress', function(file_name, file_data) {
		action_set_bios('dreamcast', 'naomi.zip', file_data, false);
	});

	FileUploader('btn_bios_demul_naomi2', 'generic_progress', function(file_name, file_data) {
		action_set_bios('dreamcast', 'naomi2.zip', file_data, false);
	});

	$('#search_text').on('input propertychange paste', on_search);
}
