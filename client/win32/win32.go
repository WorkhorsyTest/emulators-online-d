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

package win32

import (
	// #include <wtypes.h>
	// #include <winable.h>

	"strings"

	"C"
	"syscall"
	"unsafe"
)

type (
	HANDLE uintptr
	HWND HANDLE
	HRESULT int32
)

type RECT struct {
	Left int
	Top int
	Right int
	Bottom int
}

type BROWSEINFO struct {
	Owner        HWND
	Root         *uint16
	DisplayName  *uint16
	Title        *uint16
	Flags        uint32
	CallbackFunc uintptr
	LParam       uintptr
	Image        int32
}

const (
	SWP_NOSIZE                        = 0x0001
	SWP_NOMOVE                        = 0x0002
	HWND_NOTOPMOST                    = ^HWND(1) // -2
	HWND_TOPMOST                      = ^HWND(0) // -1
	MOUSEEVENTF_LEFTDOWN              = 0x0002
	MOUSEEVENTF_LEFTUP                = 0x0004
	VK_MENU                           = 0x12
	VK_RETURN                         = 0x0D
	KEYEVENTF_KEYUP                   = 0x0002
)

var (
	moduser32                         = syscall.NewLazyDLL("user32.dll")
	procGetWindowTextLength           = moduser32.NewProc("GetWindowTextLengthW")
	procGetWindowText                 = moduser32.NewProc("GetWindowTextW")
	procEnumWindows                   = moduser32.NewProc("EnumWindows")
	procGetForegroundWindow           = moduser32.NewProc("GetForegroundWindow")
	procGetDesktopWindow              = moduser32.NewProc("GetDesktopWindow")
	procShowWindow                    = moduser32.NewProc("ShowWindow")
	procSetWindowPos                  = moduser32.NewProc("SetWindowPos")
	procSetActiveWindow               = moduser32.NewProc("SetActiveWindow")
	procSetCursorPos                  = moduser32.NewProc("SetCursorPos")
	procMouseEvent                    = moduser32.NewProc("mouse_event")
	procKeybdEvent                    = moduser32.NewProc("keybd_event")
	procGetWindowRect                 = moduser32.NewProc("GetWindowRect")

	modshell32                        = syscall.NewLazyDLL("shell32.dll")
	procSHBrowseForFolder             = modshell32.NewProc("SHBrowseForFolderW")
	procSHGetPathFromIDList           = modshell32.NewProc("SHGetPathFromIDListW")
)

func KeybdEvent(bVk byte, bScan byte, dwFlags int, dwExtraInfo uint) {
	_, _, _ = procKeybdEvent.Call(
		uintptr(bVk),
		uintptr(bScan),
		uintptr(dwFlags),
		uintptr(dwExtraInfo),
	)
}

func GetWindowRect(hwnd HWND) *RECT {
	var rect RECT
	_, _, _ = procGetWindowRect.Call(
		uintptr(hwnd),
		uintptr(unsafe.Pointer(&rect)),
	)

    return &rect
}

func SetCursorPos(x int, y int) bool {
	ret, _, _ := procSetCursorPos.Call(uintptr(x), uintptr(y))
	int_ret := int(ret)
	if int_ret == 1 {
		return true
	} else {
		return false
	}
}

func MouseEvent(dwFlags int, dx int, dy int, dwData int, dwExtraInfo uint) {
	_, _, _ = procMouseEvent.Call(
		uintptr(dwFlags),
		uintptr(dx),
		uintptr(dy),
		uintptr(dwData),
		uintptr(dwExtraInfo),
	)
}

func ShowWindow(hwnd HWND, boolCmdShow bool) bool {
	var nCmdShow int
	if boolCmdShow {
		nCmdShow = 1
	} else {
		nCmdShow = 0
	}
	ret, _, _ := procShowWindow.Call(uintptr(hwnd), uintptr(nCmdShow))
	return int(ret) > 0
}

func SetActiveWindow(hwnd HWND) HWND {
	ret, _, _ := procShowWindow.Call(uintptr(hwnd))
	return HWND(ret)
}

func SetWindowPos(hwnd HWND, hWndInsertAfter HWND, x int, y int, cx int, cy int, uFlags uint) bool {
	ret, _, _ := procSetWindowPos.Call(
		uintptr(hwnd),
		uintptr(hWndInsertAfter),
		uintptr(x),
		uintptr(y),
		uintptr(cx),
		uintptr(cy),
		uintptr(uFlags),
	)

    return int(ret) != 0
}

func GetWindowTextLength(hwnd HWND) int {
	ret, _, _ := procGetWindowTextLength.Call(uintptr(hwnd))
	return int(ret)
}

func GetWindowText(hwnd HWND) string {
	textLen := GetWindowTextLength(hwnd) + 1

	buf := make([]uint16, textLen)
	procGetWindowText.Call(
		uintptr(hwnd),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(textLen))

	return syscall.UTF16ToString(buf)
}

func EnumWindows(enumFunc uintptr, lparam uintptr) (err error) {
	r1, _, e1 := syscall.Syscall(procEnumWindows.Addr(), 2, uintptr(enumFunc), uintptr(lparam), 0)
	if r1 == 0 {
		if e1 != 0 {
			err = error(e1)
		} else {
			err = syscall.EINVAL
		}
	}
	return
}

func GetForegroundWindow() (HWND) {
	ret, _, _ := procGetForegroundWindow.Call()
	return HWND(ret)
}

func GetDesktopWindow() (HWND) {
	ret, _, _ := procGetDesktopWindow.Call()
	return HWND(ret)
}

func SHGetPathFromIDList(idl uintptr) string {
	buf := make([]uint16, 1024)
	procSHGetPathFromIDList.Call(
		idl,
		uintptr(unsafe.Pointer(&buf[0])))

	return syscall.UTF16ToString(buf)
}

func SHBrowseForFolder(bi *BROWSEINFO) uintptr {
	ret, _, _ := procSHBrowseForFolder.Call(uintptr(unsafe.Pointer(bi)))
	return ret
}

func FindWindowWithTitleText(title_text string) (HWND, string) {
	// Get the handles of all the windows
	var res []HWND
	cb := syscall.NewCallback(func(h HWND, p uintptr) uintptr {
		res = append(res, h)
		return 1
	})
	EnumWindows(cb, 0)

	// Find the window with the desired title bar text
	for _, hwnd := range res {
		title := GetWindowText(hwnd)
		if strings.Contains(title, title_text) {
			return hwnd, title
		}
	}
	return 0, ""
}

