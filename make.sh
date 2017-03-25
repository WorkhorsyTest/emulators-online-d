# Copyright (c) 2015-2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# emulators-online is a HTML based front end for video game console emulators
# It uses the GNU AGPL 3 license
# It is hosted at: https://github.com/workhorsy/emulators-online-d

set -e

function build {
	g++ \
	-std=c++11 -O3 -c -I src -static -fPIC \
	uWebSockets/src/Extensions.cpp \
	uWebSockets/src/Group.cpp \
	uWebSockets/src/WebSocketImpl.cpp \
	uWebSockets/src/Networking.cpp \
	uWebSockets/src/Hub.cpp \
	uWebSockets/src/Node.cpp \
	uWebSockets/src/WebSocket.cpp \
	uWebSockets/src/HTTPSocket.cpp \
	uWebSockets/src/Socket.cpp \
	uWebSockets/src/Epoll.cpp \
	uWebSockets/src/web_socket.cpp

	dmd \
	main.d uWebSockets/web_socket.d *.o \
	-L-lstdc++ /usr/lib/x86_64-linux-gnu/libssl.a /usr/lib/x86_64-linux-gnu/libcrypto.a

	rm -f *.o
}

function clean {
	rm -f main
	rm -f *.o
	rm -f *.a
	rm -f *.so
	rm -f *.dylib
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
