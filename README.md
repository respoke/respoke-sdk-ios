Respoke SDK
================================

This project uses git submodules. Please clone the repository from Github using the recursive flag to automatically grab the submodules:
```
git clone --recursive https://<USER_NAME>@stash.digium.com/stash/scm/scl/respoke-sdk-ios.git
```

This repository contains several different parts used to build and test the Respoke SDK:

RespokeSDK - The source code to the Respoke SDK and an XCode project to build the Respoke SDK library

RespokeSDK/Public - The output directory of the distributable Respoke libraries and public header files. See the readme in this folder for instructions on how to use the Respoke SDK in a third-party application.

pull_webrtc_source.sh & build_webrtc_libs.sh - Scripts to assist in the building of the open source WebRTC framework from Google. The WebRTC libraries have been precompiled and placed into the RespokeSDK directory since the build process is very cumbersome and only needs to be done if upgrading to a new release.

Running the SDK test cases
==========================

The functional test cases that use RespokeCall require a web server with a specific Web application based on Respoke.js that is set up to automatically respond to certain actions that the SDK test cases perform. Because the web application will use audio and video, it must run from the context of a web server (and not just by loading the html from the file system). To set up your system to perform these tests, do the following:

1) Install http-server

$ sudo npm i -g http-server

2) Start http-server from the testbot directory:

$ cd RespokeSDK/RespokeSDKTests/WebTestBot/

$ http-server

3) Start Chrome using command line parameters to use fake audio/video and auto accept media permissions so that no human interaction is required:

$ /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --use-fake-ui-for-media-stream --use-fake-device-for-media-stream

This can alternately be done with Firefox by navigating to "about:config" and then setting the "media.navigator.permission.disabled" option to TRUE

4) Open the testbot in a Chrome tab by loading http://localhost:8080

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

The WebRTC source code is a nightmarish onion of layers, and can be challenging to build correctly for iOS. Build scripts have been included in this repository to automate as much of this process as possible. For a list of the many individual steps, and workarounds for frequent problems, take a look at my blog post here:

http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life/

Prerequisites:
--------------
* XCode 5.1+ with the Command Line Tools installed (Preferences -> Downloads -> Command Line Tools)
* Git installed and working

The build scripts assume that all of the WebRTC code will be placed inside of this repository's directory structure. The first step is to get the Chromium Depot Tools, which are used to pull the source code and build it later.

Step 1: Chromium tools
----------------------

From the terminal, change into the root directory of this repository wherever it lives on your system. We will assume that it resides in /projects/respoke-ios for the purposes of documentation:
```
$ cd /projects/respoke-ios
$ git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```
These are a bunch of tools used during the build process, and they will need to be in your path so you will need to modify your .bash_profile (or other shell file) and modify the PATH line like so:
```
$ export PATH=/projects/respoke-ios/depot_tools:$PATH
```
Next you will need to restart your terminal or re-run your bash profile so that the changes take effect:
```
$ source ~/.bash_profile
```
Step 2: Download the WebRTC source code
---------------------------------------

A build script has been provided to pull the correct revision of the source code:
```
$ ./pull_webrtc_source.sh
```
This will pull all of the code and associated submodules from a variety of sources. Expect this to take a long time to finish, and will require ~1.5 GB of storage space. If you would like to use a newer version of the WebRTC source, then edit this file and change the first line to define the specific revision # you are interested in using. I highly recommend one of the stable releases, as the daily builds seem to break somewhat regularly.

Step 3: Build the libraries
---------------------------

Another build script has been provided to handle actually building the libraries.
```
$ ./build_webrtc_libs.sh
```
This will build the massive WebRTC source, combine the assorted libraries into universal simulator/device compatible libraries, and then replace the compiled libraries and associated headers inside of the Respoke iOS project with the new ones. Once it completes successfully, you should be able to open the XCode project, recompile and go.

If you encounter an error during the build phase, there are a multitude of things that could have gone wrong. If you see this error in particular:
```
AssertionError: Multiple codesigning fingerprints for identity: iPhone Developer
```
Go check out the "Curveball: codesigning" section of my blog post for workarounds. 

Notes about WebRTC libraries
----------------------------

The open source WebRTC libraries currently do not build for the armv7s or arm64 architectures, so it's necessary that any XCode project using this library skip those architectures (they are part of the standard architectures defined for new projects). The libraries built here will still run on armv7s and arm64 devices (the newest) but will not be 100% optimized for them. You will get a build error if you try to build for the armv7s or arm64 architecture.

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
