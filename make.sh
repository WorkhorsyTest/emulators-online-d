# Copyright (c) 2015-2018 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# emulators-online is a HTML based front end for video game console emulators
# It uses the GNU AGPL 3 license
# It is hosted at: https://github.com/workhorsy/emulators-online-d

set -e

WRAP_BINARY=false
ARCH=x86_64

function build {
	# Make sure DMD is installed
	if ! type dmd >/dev/null 2>&1; then
		echo "DMD was not found. Please install DMD." >&2
		return
	fi

	rm -f emulators_online_client.exe
	rm -f emulators_online_client
	#rm -f client/identify_games/identify_games.exe
	rm -f client/emulators_online_client
	rm -f client/wrap_binary/wrapper_generator

	# Put everything inside the generated D file
	echo "!!! Generating files ..."
	cd client/generate
	dub run --arch=$ARCH
	rm -f generate_included_files
	cd ..

	# Build the client exe
	echo "!!! Building emulators_online_client ..."
	cd src
	dub build --arch=$ARCH #--build=release
	rm -f ../generate/generated_files.d
	#OS=`uname -o`
	#if [ "$OS" = "Msys" ]; then
	#	mv libeay32.dll ../../libeay32.dll
	#	mv libevent.dll ../../libevent.dll
	#	mv ssleay32.dll ../../ssleay32.dll
	#fi
	mv emulators_online_client ../../emulators_online_client
	cd ..

	if [ "$WRAP_BINARY" = true ]; then
		echo "!!! Copying binary into wrapper source code ..."
		cd wrap_binary
		dub build --arch=$ARCH
		./wrapper_generator
		rm -f wrapper_generator
		cd ..

		echo "!!! Building binary wrapper ..."
		cd wrapped_client/
		dub build --arch=$ARCH #--build=release
		rm -f wrapped.d
		cd ..
		rm -f ../emulators_online_client
		mv wrapped_client/emulators_online_client ../emulators_online_client
		cd ..
	fi
	cd ..
	echo "!!! Done!"

	echo "!!! Running ..."
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
