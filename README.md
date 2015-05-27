Respoke SDK for iOS
================================

The Respoke SDK for iOS makes it easy to add live voice, video, text, and data features to your mobile app. For information on how to use the SDK, take a look at our developer documentation and sample apps here:

[https://docs.respoke.io/](https://docs.respoke.io/)

Installing the SDK
=============

The Respoke iOS SDK is available to install via CocoaPods.

Add the following to your Podfile:

    ipod 'RespokeSDK'


Then run:

    pod install

Contributing
============

We welcome pull requests to improve the SDK for everyone. When submitting changes, please make sure you have run the SDK test cases before submitting and added/modified any tests that are affected by your improvements.

Running the SDK test cases
==========================

The functional test cases that use RespokeCall require a specific Web application based on Respoke.js that is set up to automatically respond to certain actions that the SDK test cases perform. Because the web application will use audio and video, it requires special user permissions from browsers that support WebRTC and typically requires user interaction. Therefore it must run from either the context of a web server, or by loading the html file from the file system with specific command line parameters for Chrome. 

Additionally, the Android Studio test project has been set up to expect that the web application will connect to Respoke with a specific endpoint ID in the following format:

testbot-username

This username is the user that you are logged into your development computer with when you run the tests. This is done to avoid conflicts that can occur when multiple developers are running multiple instances of the test web application simultaneously. 

To set up your system to perform these tests, do one of the following:

#### A) Load the html from a file with Chrome.


1) You can use command line parameters to load the test bot with Chrome tell it to use a fake audio and video source during testing. On Mac OS, the command would look like this:

    $ "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --use-fake-ui-for-media-stream \
    --use-fake-device-for-media-stream \
    --allow-file-access-from-files \
    ./RespokeSDKTests/WebTestBot/index.html &

2) Once the file has loaded, append your local username to the URL to match what Android Studio will search for as the tests run:

    file:///respoke-android-sdk/respokeSDK/WebTestBot/index.html#?un=mymacusername

3) Run the SDK test cases



#### B) Run with a local web server.


1) Install http-server

    $ sudo npm i -g http-server

2) Start http-server from the testbot directory:

    $ cd respokeSDK/WebTestBot/
    $ http-server

3) Start Chrome using command line parameters to use fake audio/video and auto accept media permissions so that no human interaction is required:

    $ /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --use-fake-ui-for-media-stream --use-fake-device-for-media-stream

This can alternately be done with Firefox by navigating to "about:config" and then setting the "media.navigator.permission.disabled" option to TRUE

4) Open the testbot in a Chrome tab by loading http://localhost:8080/#?un=mymacusername

5) Run the SDK test cases


License
=======

The Respoke SDK and demo applications are licensed under the MIT license. Please see the [LICENSE](LICENSE) file for details.
