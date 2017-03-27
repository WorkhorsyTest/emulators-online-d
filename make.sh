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
	cd client/generate
	dub run
	rm -f generate_included_files
	cd ..

	# Remove the exes
	rm -f emulators_online_client.exe
	rm -f emulators_online_client
	#rm -f client/identify_games/identify_games.exe

	# Build the client exe
	echo "Building emulators_online_client ..."
	dub build
	mv emulators_online_client ../emulators_online_client
	OS=`uname -o`
	if [ "$OS" = "Msys" ]; then
		mv libeay32.dll ../libeay32.dll
		mv libevent.dll ../libevent.dll
		mv ssleay32.dll ../ssleay32.dll
	fi

	cd ..

	echo "Running ..."
	./emulators_online_client
}

function clean {
	rm -f *.exe
	rm -f *.dll
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
