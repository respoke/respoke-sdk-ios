Respoke SDK
================================

This project uses git submodules. Please clone the repository from Github using the recursive flag to automatically grab the submodules:

```
git clone --recursive https://github.com/respoke/respoke-sdk-ios.git
```

This repository contains several different parts used to build and test the Respoke SDK:

RespokeSDK - The source code to the Respoke SDK and an XCode project to build the Respoke SDK library

RespokeSDK/Public - The output directory of the distributable Respoke libraries and public header files. See the readme in this folder for instructions on how to use the Respoke SDK in a third-party application.

RespokeSDKTests - A Test project with a test UI for functional & unit testing

build_webrtc.sh - Script to assist in the building of the open source WebRTC framework from Google. The WebRTC libraries have been precompiled and placed into the RespokeSDK directory since the build process is very cumbersome and only needs to be done if upgrading to a new release. Script relies on build scripts from https://github.com/pristineio/webrtc-build-scripts/


Running the SDK test cases
==========================

The functional test cases that use RespokeCall require a specific Web application based on Respoke.js that is set up to automatically respond to certain actions that the SDK test cases perform. Because the web application will use audio and video, it requires special user permissions from browsers that support WebRTC and typically requires user interaction. Therefore it must run from either the context of a web server, or by loading the html file from the file system with specific command line parameters for Chrome. 

Additionally, the XCode test project has been set up to expect that the web application will connect to Respoke with a specific endpoint ID in the following format:

testbot-username

This username is the user that you are logged into your development computer with when you run the tests. This is done to avoid conflicts that can occur when multiple developers are running multiple instances of the test web application simultaneously. 

To set up your system to perform these tests, do one of the following:

A) Load the html from a file with Chrome. 

1) Run the following command to command Chrome to start the test bot and use a fake audio and video source during testing

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --use-fake-ui-for-media-stream \
    --use-fake-device-for-media-stream \
    --allow-file-access-from-files \
    ./RespokeSDKTests/WebTestBot/index.html &

2) Once the file has loaded, append your local username to the URL to match what XCode will search for as the tests run:

file:///projects/respoke-ios/RespokeSDK/RespokeSDKTests/WebTestBot/index.html#?un=jasonadams

3) Run the SDK test cases



B) Run with a local web server.


1) Install http-server

$ sudo npm i -g http-server

2) Start http-server from the testbot directory:

$ cd RespokeSDKTests/WebTestBot/

$ http-server

3) Start Chrome using command line parameters to use fake audio/video and auto accept media permissions so that no human interaction is required:

$ /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --use-fake-ui-for-media-stream --use-fake-device-for-media-stream

This can alternately be done with Firefox by navigating to "about:config" and then setting the "media.navigator.permission.disabled" option to TRUE

4) Open the testbot in a Chrome tab by loading http://localhost:8080/#?un=username

5) Run the SDK test cases


Working with the RespokeSDK
===========================

For most purposes, what you want to do is the following:

1) Open the RespokeSDK/RespokeSDK.xcodeproj project in XCode
2) Make code changes as necessary to the SDK
3) Build the UniversalLib target. This will automatically build the SDK library for armv7, arm64, and x86, combine the output into a single library and place it in the RespokeSDK/Public directory
4) Zip up the contents of the RespokeSDK/Public directory and give it to third party developers. That directory contains instructions on how to incorporate the SDK into a third-party application.
5) Rejoice

If you would like to modify or update the WebRTC libraries, then follow the instructions below.


Building the WebRTC libraries from scratch
==========================================

The open-source code lives here:

https://code.google.com/p/webrtc/

The WebRTC source code is a nightmarish onion of layers, and can be challenging to build correctly for iOS. A build script has been included in this repository to automate as much of this process as possible. For a list of the many individual steps, and workarounds for frequent problems, take a look at my blog post here:

http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life/

Prerequisites:
--------------
* XCode 5.1+ with the Command Line Tools installed (Preferences -> Downloads -> Command Line Tools)
* Git installed and working

The build scripts assume that all of the WebRTC code will be placed inside of this repository's directory structure. The first step is to get the Chromium Depot Tools, which are used to pull the source code and build it later.

A build script has been provided to pull and build the source code as well as deploy the WebRTC headers and libraries to the RespokeSDK project directory.

```
Step 1: Download build tools and WebRTC source code
---------------------------------------------------

To pull the sources:
```
$ ./build_webrtc.sh pull
```
This will pull all of the code and associated submodules from a variety of sources. Expect this to take a long time to finish, and will require ~1.5 GB of storage space. If you would like to use a newer version of the WebRTC source, refer to the webrtc-build-scripts README for info on how to do that. I highly recommend one of the stable releases, as the daily builds seem to break somewhat regularly.

Step 2: Build the libraries
---------------------------

To build the sources:
```
$ ./build_webrtc.sh build
```

If you encounter an error during the build phase, there are a multitude of things that could have gone wrong. If you see this error in particular:
```
AssertionError: Multiple codesigning fingerprints for identity: iPhone Developer
```
Go check out the "Curveball: codesigning" section of my blog post for workarounds. 

NOTE: The build script will throw an error if it detects multiple code signing fingerprints. You should resolve the issue before proceeding. To proceed, you will have to change the line in the build script from:
```
check_code_signing "ERROR"
```
to:
```
check_code_signing "WARNING"
```

Step 3: Deploy the libraries
-----------------------------

To deploy the WebRTC binaries and headers:
```
$ ./build_webrtc.sh deploy
```
This will combine the assorted libraries into universal simulator/device compatible libraries, and then replace the compiled libraries and associated headers inside of the Respoke iOS project with the new ones. Once it completes successfully, you should be able to open the XCode project, recompile and go.

NOTE: The WebRTC revision number will be saved in RespokeSDK/Public/libs/WEBRTC_REVISION.txt

Notes about WebRTC libraries
----------------------------

The WebRTC libraries are also currently built in release mode. some of them are very large (greater than 50 MB), so they cannot be combined into a single library since it will be larger than some revision control systems (specifically Github) allow. To get around this, the libraries are all included into the project individually, with some of them marked as "optional" since they only apply to specific architectures (like the simulator or actual iOS devices). This will produce some warnings during the linking step of compilation, but they can be ignored. The libraries in question are:

lib_core_neon_offsets.a
libaudio_processing_neon.a 
libaudio_processing_sse2.a 
libcommon_audio_sse2.a 
libcommon_audio_neon.a 
libisac_neon.a 
libjingle_p2p_armv7.a 
libjingle_p2p_x86.a 
libvideo_processing_sse2.a 
libvpx_asm_offsets_vpx_scale.a
libvpx_intrinsics_mmx.a 
libvpx_intrinsics_sse2.a 
libvpx_intrinsics_sse4_1.a 
libvpx_intrinsics_ssse3.a
libyuv_neon.a 


License
=======

The Respoke SDK and demo applications are licensed under the MIT license. Please see the [LICENSE](LICENSE) file for details.
