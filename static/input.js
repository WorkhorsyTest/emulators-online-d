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



KEYBOARD_JS_CODE_MAP = {
	0 : 'none',
	27 : 'ESCAPE',
	49 : '1',
	50 : '2',
	51 : '3',
	52 : '4',
	53 : '5',
	54 : '6',
	55 : '7',
	56 : '8',
	57 : '9',
	48 : '0',
	109 : 'MINUS',
	187 : 'EQUALS',
	8 : 'BACKSPACE',
	9 : 'TAB',
	81 : 'Q',
	87 : 'W',
	69 : 'E',
	82 : 'R',
	84 : 'T',
	89 : 'Y',
	85 : 'U',
	73 : 'I',
	79 : 'O',
	80 : 'P',
	219 : 'LBRACKET',
	221 : 'RBRACKET',
	13 : 'RETURN',
	17 : 'LCONTROL',
	65 : 'A',
	83 : 'S',
	68 : 'D',
	70 : 'F',
	71 : 'G',
	72 : 'H',
	74 : 'J',
	75 : 'K',
	76 : 'L',
	186 : 'SEMICOLON',
	222 : 'APOSTROPHE',
	192 : 'GRAVE',
	16 : 'LSHIFT',
	220: 'BACKSLASH',
	90 : 'Z',
	88 : 'X',
	67 : 'C',
	86 : 'V',
	66 : 'B',
	78 : 'N',
	77 : 'M',
	188 : 'COMMA',
	190 : 'PERIOD',
	191 : 'SLASH',
	16 : 'RSHIFT',
	106 : 'MULTIPLY',
	18 : 'LMENU',
	32 : 'SPACE',
	20 : 'CAPITAL', // Caps Lock
	112 : 'F1',
	113 : 'F2',
	114 : 'F3',
	115 : 'F4',
	116 : 'F5',
	117 : 'F6',
	118 : 'F7',
	119 : 'F8',
	120 : 'F9',
	121 : 'F10',
	144 : 'NUMLOCK',
	145 : 'SCROLL',	
	103 : 'NUMPAD7',
	104 : 'NUMPAD8',
	105 : 'NUMPAD9',
	109 : 'SUBTRACT',
	100 : 'NUMPAD4',
	101 : 'NUMPAD5',
	102 : 'NUMPAD6',
	107 : 'ADD',
	97 : 'NUMPAD1',
	98 : 'NUMPAD2',
	99 : 'NUMPAD3',
	96 : 'NUMPAD0',
	110 : 'DECIMAL',
	122 : 'F11',
	123 : 'F12',
	/*
	'F13',
	'F14',
	'F15',
	'F16',
	'F17',
	'F18',
	'KANA',
	'F19',
	'CONVERT',
	'NOCONVERT',
	'YEN'# ¥
	'NUMPADEQUALS',
	'CIRCUMFLEX', # ^
	'AT', # @
	'COLON', # :
	'UNDERLINE', # _
	'KANJI',
	'STOP',
	'AX',
	'UNLABLED',
	13 : 'NUMPADENTER',
	17 : 'RCONTROL',
	'SECTION',
	'NUMPADCOMMA',
	111 : 'DIVIDE',
	'SYSRQ',
	*/
	18 : 'RMENU', // Right Menu/Alt
	//'FUNCTION',
	19 : 'PAUSE', 
	36 : 'HOME',
	38 : 'UP',
	33 : 'PRIOR', // Page Up
	37 : 'LEFT', // Left Arrow
	39 : 'RIGHT', // Right Arrow
	35 : 'END',
	40 : 'DOWN', // Down Arrow
	34 : 'NEXT', // Page Down
	45 : 'INSERT',
	46 : 'DELETE',
	91 : 'LMETA', // Left Meta/Super
	//'LWIN',
	//'RMETA', # Right Meta/Super
	//'RWIN',
	//'APPS',
	//'POWER',
	//'SLEEP'
};

var gamepad = null;

// Find already connected pads
if(navigator.getGamepads) {
	$.each(navigator.getGamepads(), function(i, pad) {
		if(pad && pad.id) {
			gamepad = pad;
			console.log("Gamepad connected at index " + gamepad.index + ": " + gamepad.id + ". It has " + gamepad.buttons.length + " buttons and " + gamepad.axes.length + " axes.");
			return false;
		}
	});
}

// Handle connecting and disconnecting pads
function gamepad_handler(e, connecting) {
	if (connecting) {
		gamepad = navigator.getGamepads()[e.gamepad.index];
		if(gamepad)
			console.log("Gamepad connected at index " + gamepad.index + ": " + gamepad.id + ". It has " + gamepad.buttons.length + " buttons and " + gamepad.axes.length + " axes.");
	} else {
		gamepad = null;
	}
}

window.addEventListener("gamepadconnected", function(e) { gamepad_handler(e, true); }, false);
window.addEventListener("gamepaddisconnected", function(e) { gamepad_handler(e, false); }, false);

var is_polling_buttons = false;

function start_polling_buttons(done_cb) {
	is_polling_buttons = true;

	// Check the pressed buttons every 300 ms
	var interval = setInterval(function() {
		var pressed_button = get_pressed_button();
		if(pressed_button != -1) {
			is_polling_buttons = false;
		}

		if(!is_polling_buttons) {
			done_cb(pressed_button);
			clearInterval(interval);
		}
	}, 100);

	// Stop checking after 5 seconds
	setTimeout(function() {
		is_polling_buttons = false;
	}, 5000);
}

function get_pressed_button() {
	var all_pads = navigator.getGamepads();
	if(all_pads.length < 1)
		return -1;

	gamepad = all_pads[0];

	if(gamepad == null || gamepad.buttons == null)
		return -1;

	for(var i in gamepad.buttons) {
		var button = gamepad.buttons[i];
		if(button) {
			if(typeof(button) == 'object') {
				if(button.pressed) {
					return 'button_' + i;
				}
			} else if(button) {
				return 'button_' + i;
			}
		}
	}

	for(var i in gamepad.axes) {
		var axis = gamepad.axes[i];
		var sign = axis > 0 ? '+' : '-';
		if(Math.abs(axis) > 0.5) {
			return 'axes_' + i + sign;
		}
	}

	return -1;
}
