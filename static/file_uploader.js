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


var FileUploader = function(file_id, progress_percent_id, done_cb) {
	file_reader = null;
	file_name = null;
	progress_percent = document.getElementById(progress_percent_id);

	function on_error(evt) {
		switch(evt.target.error.code) {
			case evt.target.error.NOT_FOUND_ERR:
				alert('File Not Found!');
				break;
			case evt.target.error.NOT_READABLE_ERR:
				alert('File is not readable');
				break;
			case evt.target.error.ABORT_ERR:
				break;
			default:
				alert('An error occurred reading this file.');
		};
	}

	function on_abort(evt) {
		alert('File read cancelled');
	}

	function on_progress(evt) {
		// evt is an ProgressEvent
		if (evt.lengthComputable) {
			var percentLoaded = Math.round((evt.loaded / evt.total) * 100);
			// Increase the progress bar length
			if (percentLoaded < 100) {
				progress_percent.textContent = percentLoaded + '%';
			}
		}
	}

	function on_done(evt) {
		// Set the progress bar to 100%
		progress_percent.textContent = '100%';
		progress_percent.style.display = 'none';

		done_cb(file_name, evt.target.result);
	}

	function handle_file_select(evt) {
		// Reset the progress bar
		progress_percent.textContent = '0%';

		// Set all the callbacks
		file_reader = new FileReader();
		file_reader.onprogress = on_progress;
		file_reader.onload = on_done;
		file_reader.onerror = on_error;
		file_reader.onabort = on_abort;

		// Read the file content
		file_name = evt.target.files[0].name;
		file_reader.readAsBinaryString(evt.target.files[0]);
	}

	document.getElementById(file_id).addEventListener('change', handle_file_select, false);
};

function inspect(obj) {
	console.log("/////////////////////////////////////////////////////");
	for(var key in obj) {
		 if (obj.hasOwnProperty(key)) {
			if("selectionDirection"==key || "selectionEnd"==key || "selectionStart"==key)
				continue;
			console.log(key + ": " + obj[key]);
		}
	}
	console.log("/////////////////////////////////////////////////////");
}


