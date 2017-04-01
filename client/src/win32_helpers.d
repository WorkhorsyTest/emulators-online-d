

module win32_helpers;

static import win32.windef;
static import win32.winuser;
static import win32.shlobj;
import std.stdio;
import std.string;
import std.conv;

private win32.winuser.HWND[] g_hwnds;

win32.winuser.HWND GetForegroundWindow() {
	return win32.winuser.GetForegroundWindow();
}

string GetWindowText(win32.winuser.HWND hwnd) {
	char[255] chr_text;
	int ret = win32.winuser.GetWindowText(hwnd, chr_text.ptr, chr_text.length);
	string text = chr_text.ptr.fromStringz.to!string;
	return text;
}

win32.winuser.HWND GetWindowByText(string text) {
	g_hwnds = [];
	extern (Windows) int enum_cb(win32.winuser.HWND hWnd, win32.winuser.LPARAM lParam) {
		//stdout.writefln("??? hWnd: %s", hWnd);
		//stdout.flush();
		g_hwnds ~= hWnd;
		return 1;
	}

	//stdout.writefln("??? g_hwnds: %s", g_hwnds);
	//stdout.flush();

	win32.winuser.LPARAM lParam = 0;
	//WNDENUMPROC hwnd_cb = &enum_cb;
	win32.winuser.EnumWindows(&enum_cb, lParam);
	if (g_hwnds.length > 0) {
		return g_hwnds[0];
	} else {
		return null;
	}
}

win32.winuser.HWND GetBrowserWindow() {
	import std.algorithm.searching;

	const string[] browser_texts = [
		" - Mozilla Firefox",
		" - Google Chrome",
		" - Opera",
		" ‎- Microsoft Edge", // NOTE: The "-" is actually "â€Ž-" for some reason
		" - Internet Explorer",
	];

	// First try checking if the browser is the foreground window
	win32.winuser.HWND hwnd = GetForegroundWindow();
	string text = GetWindowText(hwnd);
	foreach (browser_text; browser_texts) {
		if (text.canFind(browser_text)) {
			return hwnd;
		}
	}

	// If the browser is not in the foreground, look through all windows
	// and see if any are a browser.
	foreach (browser_text; browser_texts) {
		hwnd = GetWindowByText(browser_text);
		if (hwnd != null) {
			return hwnd;
		}
	}

	return null;
}

string DialogDirectorySelect(win32.winuser.HWND hwnd) {
	// FIXME: How do we pass the string to display?
	win32.shlobj.BROWSEINFO browse_info = {
		hwnd,
		null, //desktop_pidl,
		null,
		null, // "Select a folder search for games"
		0,
		null,
		0,
		0,
	};
	win32.shlobj.ITEMIDLIST* pidl = win32.shlobj.SHBrowseForFolder(&browse_info);
	if (pidl != null) {
		char[255] chr_dir_name;
		int ret = win32.shlobj.SHGetPathFromIDList(pidl, chr_dir_name.ptr);
		string dir_name = chr_dir_name.ptr.fromStringz.to!string;
		//stdout.writefln("??????????????? ret: %s", ret);
		//stdout.writefln("??????????????? dir_name: %s", dir_name);
		return dir_name;
	} else {
		return null;
	}
}

void MessageBox(string text, string title) {
	import std.string;
	int flags = win32.winuser.MB_OK | win32.winuser.MB_ICONEXCLAMATION;
	win32.winuser.MessageBox(null, title.toStringz, text.toStringz, flags);
}

auto toUTF16z(S)(S s) {
	import std.utf;
	return toUTFz!(const(wchar)*)(s);
}
