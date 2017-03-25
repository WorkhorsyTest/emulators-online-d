# Copyright (c) 2015-2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# emulators-online is a HTML based front end for video game console emulators
# It uses the GNU AGPL 3 license
# It is hosted at: https://github.com/workhorsy/emulators-online-d

set -e

function build {
	# Make sure G++ is installed
	if ! type g++ >/dev/null 2>&1; then
		echo "G++ was not found. Please install G++ or MinGW." >&2
		return
	fi

	# Make sure DMD is installed
	if ! type dmd >/dev/null 2>&1; then
		echo "DMD was not found. Please install DMD." >&2
		return
	fi

	# Put everything inside the generated D file
	echo "Generating files ..."
	rdmd -g client/generate/generate_included_files.d

	mkdir build
	cd build

	echo "Building uWebSockets ..."
	g++ \
	-std=c++11 -g -O3 -c -fPIC \
	../uWebSockets/src/Extensions.cpp \
	../uWebSockets/src/Group.cpp \
	../uWebSockets/src/WebSocketImpl.cpp \
	../uWebSockets/src/Networking.cpp \
	../uWebSockets/src/Hub.cpp \
	../uWebSockets/src/Node.cpp \
	../uWebSockets/src/WebSocket.cpp \
	../uWebSockets/src/HTTPSocket.cpp \
	../uWebSockets/src/Socket.cpp \
	../uWebSockets/src/Epoll.cpp \
	../uWebSockets/src/web_socket.cpp

	echo "Building emulators-online ..."
	dmd \
	../emulators_online_client.d ../uWebSockets/web_socket.d *.o \
	-L-lstdc++ /usr/lib/x86_64-linux-gnu/libssl.a /usr/lib/x86_64-linux-gnu/libcrypto.a
	mv emulators_online_client ../emulators_online_client

	cd ..
	rm -f -rf build
}

function clean {
	rm -f emulators_online_client
	rm -f *.o
	rm -f *.a
	rm -f *.so
	rm -f *.dylib
	rm -f -rf build
}

# If there are no arguments, print the correct usage
if [ "$#" -ne 1 ]; then
	echo "Build and run emulators_online_client.exe" >&2
	echo "Usage: ./make.sh port" >&2
	echo "Example: ./make.sh 9090" >&2
# Or build the software
else
	clean
	build $@
fi
