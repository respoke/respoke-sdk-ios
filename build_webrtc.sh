# Copyright 2015, Digium, Inc.
# All rights reserved.
#
# This source code is licensed under The MIT License found in the
# LICENSE file in the root directory of this source tree.
#
# For all details and documentation:  https://www.respoke.io

IDENTITY="iPhone Developer"
RESPOKE_LIB_DIR="./RespokeSDK/Public/libs"

function num_fingerprints() {
	echo $(security find-identity -v | grep -c "$IDENTITY")
}

function check_code_signing() {
	WARN_ERROR="WARNING"
	if [ $# -gt 0 ]; then
		WARN_ERROR="$1"
	fi

	if [ $(num_fingerprints) -gt 1 ]; then
		echo -e "$WARN_ERROR: You have multiple code signing fingerprints for $IDENTITY.\n"\
			"Check out the 'Curveball: codesigning' section of\n"\
			"http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life"
		if [ "$WARN_ERROR" == "ERROR" ]; then
			exit 1
		fi
	fi
}

function create_revision_file() {
	source webrtc-build-scripts/ios/build.sh
	echo "WebRTC Rev: $(get_revision_number)" > $RESPOKE_LIB_DIR/WEBRTC_REVISION.txt
}

function pull() {
	echo "======================="
	echo "===> Pulling sources..."
	echo "======================="

	check_code_signing "WARNING"

	if [ -d webrtc-build-scripts ]; then
		echo "Whoa! The webrtc-build-scripts repo already exists. Bailing..."
		exit 1
        fi

	git clone https://github.com/pristineio/webrtc-build-scripts.git &&
		pushd webrtc-build-scripts &&
		source ios/build.sh &&
		get_webrtc &&
		popd 
}

function build() {
	echo "========================"
	echo "===> Building sources..."
	echo "========================"

	check_code_signing "ERROR"

	pushd webrtc-build-scripts &&
		source ios/build.sh &&
		export WEBRTC_RELEASE=true &&
		build_webrtc &&
		popd 
}

function deploy() {
	echo "====================================="
	echo "===> Deploying headers and binaries.."
	echo "====================================="

	RTC_SRC=webrtc-build-scripts/ios/webrtc/src
	IOS_SIM=$RTC_SRC/out_ios_x86
	IOS_SIM64=$RTC_SRC/out_ios_x86_64
	IOS_ARMV7=$RTC_SRC/out_ios_armeabi_v7a
	IOS_ARM64=$RTC_SRC/out_ios_arm64_v8a

	# remove old files
	rm -f ./RespokeSDK/WebRTC/*.*
	rm -f $RESPOKE_LIB_DIR/*.a

	# copy webrtc headers
	cp $RTC_SRC/talk/app/webrtc/objc/public/*.h ./RespokeSDK/WebRTC/

	# create simulator libs
	libtool -static -o $IOS_SIM/libWebRTC-sim.a $IOS_SIM/Release-iphonesimulator/*.a
	strip -S -x -o $IOS_SIM/libWebRTC-sim-min.a -r $IOS_SIM/libWebRTC-sim.a

	# create simulator libs
	libtool -static -o $IOS_SIM64/libWebRTC-sim.a $IOS_SIM64/Release-iphonesimulator/*.a
	strip -S -x -o $IOS_SIM64/libWebRTC-sim-min.a -r $IOS_SIM64/libWebRTC-sim.a

	# create armv7 libs
	libtool -static -o $IOS_ARMV7/libWebRTC-ios.a $IOS_ARMV7/Release-iphoneos/*.a
	strip -S -x -o $IOS_ARMV7/libWebRTC-ios-min.a -r $IOS_ARMV7/libWebRTC-ios.a

	# create arm64 libs
	libtool -static -o $IOS_ARM64/libWebRTC-ios64.a $IOS_ARM64/Release-iphoneos/*.a
	strip -S -x -o $IOS_ARM64/libWebRTC-ios64-min.a -r $IOS_ARM64/libWebRTC-ios64.a

        # create universal lib
	lipo -create $IOS_SIM/libWebRTC-sim-min.a $IOS_SIM64/libWebRTC-sim-min.a $IOS_ARMV7/libWebRTC-ios-min.a $IOS_ARM64/libWebRTC-ios64-min.a -output $RESPOKE_LIB_DIR/libWebRTC.a

	# save the webrtc revision number
	create_revision_file
}

function usage() {
	echo "USAGE: $0 <pull> | <build> | <deploy>"
}

if [ $# -eq 0 ]; then
	usage
else
	# call the function passed in as argument
	$1
fi
