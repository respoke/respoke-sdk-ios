//
//  CallingTests.m
//  RespokeSDK
//
//  Created by Jason Adams on 1/27/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import "RespokeTestCase.h"
#import "RespokeEndpoint+private.h"
#import "Respoke+private.h"
#import "RespokeCall+private.h"
#import "AppDelegate.h"
#import "ViewController.h"

#define TEST_BOT_HELLO_MESSAGE @"Hi testbot!"
#define TEST_BOT_HELLO_REPLY @"Hey pal!"
#define TEST_BOT_CALL_ME_MESSAGE @"Testbot! Call me sometime! Or now!"
#define TEST_BOT_CALL_ME_VIDEO_MESSAGE @"Testbot! Call me using video!"
#define TEST_BOT_HANGUP_MESSAGE @"Hang up dude. I'm done talking."


@interface CallingTests : RespokeTestCase <RespokeClientDelegate, RespokeEndpointDelegate, RespokeCallDelegate> {
    BOOL callbackDidSucceed;
    BOOL messageReceived;
    BOOL testbotIsListening;
    BOOL didConnect;
    BOOL didHangup;
    BOOL incomingCallReceived;
    RespokeCall *incomingCall;
}

@end


@implementation CallingTests


- (void)testVoiceCalling
{
    // Create a client to test with
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client, @"Should create test client");
    [client setBaseURL:TEST_RESPOKE_BASE_URL];
    
    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    XCTAssertNotNil(testEndpointID, @"Should create test endpoint id");
    
    asyncTaskDone = NO;
    client.delegate = self;
    [client connectWithEndpointID:testEndpointID appID:TEST_APP_ID reconnect:YES initialPresence:nil errorHandler:^(NSString *errorMessage) {
        XCTAssertTrue(NO, @"Should successfully connect. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];

    [self waitForCompletion:TEST_TIMEOUT];

    XCTAssertTrue([client isConnected], @"First client should connect");
    
    
    // If things went well, there should be a web page open on the test host running a Transporter app that is logged in as testbot. It is set up to automatically answer any calls placed to it for testing purposes.


    RespokeEndpoint *testbotEndpoint = [client getEndpointWithID:TEST_BOT_ENDPOINT_ID skipCreate:NO];
    XCTAssertNotNil(testbotEndpoint, @"Should create endpoint instance");
    testbotEndpoint.delegate = self;
    
    // Send a quick message to make sure the test UI is running and produce a meaningful test error message
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [testbotEndpoint sendMessage:TEST_BOT_HELLO_MESSAGE successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = messageReceived; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(messageReceived, @"Should call onMessage delegate when a message is received");
    
    XCTAssertTrue(testbotIsListening, @"Testbot web UI is not running. Please start it and try again.");
    
    // If the web testbot is not running, don't bother trying the rest since the test has already failed
    if (testbotIsListening)
    {
        // Try to call the testbot, which should automatically answer
        asyncTaskDone = NO;
        RespokeCall *call = [testbotEndpoint startAudioCallWithDelegate:self];
        
        [self waitForCompletion:CALL_TEST_TIMEOUT];
        XCTAssertTrue(didConnect, @"Call should be established");
        XCTAssertTrue([call isCaller], @"Call should indicate that it is the caller");
        XCTAssertTrue(testbotEndpoint == [call getRemoteEndpoint], @"Should indicate call is with the endpoint that the call was started from");
        XCTAssertTrue(call.audioOnly, @"Should indicate this is an audio-only call");
        
        // Let the call run for a while to make sure it is stable
        asyncTaskDone = NO;
        [self waitForCompletion:1 assertOnTimeout:NO];
        XCTAssertTrue([call hasAudio], @"Should indicate the call has audio");
        XCTAssertTrue(![call hasVideo], @"Should indicate the call does not have video");
        
        // Mute the audio
        [call muteAudio:YES];
        asyncTaskDone = NO;
        [self waitForCompletion:1 assertOnTimeout:NO];
        
        XCTAssertTrue(!didHangup, @"Should not have hung up the call yet");
        
        // un-Mute the audio
        [call muteAudio:NO];
        asyncTaskDone = NO;
        [self waitForCompletion:1 assertOnTimeout:NO];
        
        XCTAssertTrue(!didHangup, @"Should not have hung up the call yet");
        
        asyncTaskDone = NO;
        [call hangup:YES];
        [self waitForCompletion:1 assertOnTimeout:NO];
        
        XCTAssertTrue(didHangup, @"Should have hung up the call");
    }
}


- (void)testVideoCalling
{
    // Create a client to test with
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client, @"Should create test client");
    [client setBaseURL:TEST_RESPOKE_BASE_URL];
    
    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    XCTAssertNotNil(testEndpointID, @"Should create test endpoint id");
    
    asyncTaskDone = NO;
    client.delegate = self;
    [client connectWithEndpointID:testEndpointID appID:TEST_APP_ID reconnect:YES initialPresence:nil errorHandler:^(NSString *errorMessage) {
        XCTAssertTrue(NO, @"Should successfully connect. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    
    XCTAssertTrue([client isConnected], @"First client should connect");
    
    
    // If things went well, there should be a web page open on the test host running a Transporter app that is logged in as testbot. It is set up to automatically answer any calls placed to it for testing purposes.
    
    
    RespokeEndpoint *testbotEndpoint = [client getEndpointWithID:TEST_BOT_ENDPOINT_ID skipCreate:NO];
    XCTAssertNotNil(testbotEndpoint, @"Should create endpoint instance");
    testbotEndpoint.delegate = self;
    
    // Send a quick message to make sure the test UI is running and produce a meaningful test error message
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [testbotEndpoint sendMessage:TEST_BOT_HELLO_MESSAGE successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = messageReceived; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(messageReceived, @"Should call onMessage delegate when a message is received");
    
    XCTAssertTrue(testbotIsListening, @"Testbot web UI is not running. Please start it and try again.");
    
    // If the web testbot is not running, don't bother trying the rest since the test has already failed
    if (testbotIsListening)
    {
        // Try to call the testbot, which should automatically answer
        asyncTaskDone = NO;
        ViewController *viewController = (ViewController*) ((AppDelegate*) [UIApplication sharedApplication].delegate).window.rootViewController;
        RespokeCall *call = [testbotEndpoint startVideoCallWithDelegate:self remoteVideoView:viewController.remoteView localVideoView:viewController.localView];
        
        [self waitForCompletion:CALL_TEST_TIMEOUT];
        XCTAssertTrue(didConnect, @"Call should be established");
        XCTAssertTrue([call isCaller], @"Call should indicate that it is the caller");
        XCTAssertTrue(testbotEndpoint == [call getRemoteEndpoint], @"Should indicate call is with the endpoint that the call was started from");
        XCTAssertTrue(!call.audioOnly, @"Should indicate this is an audio-only call");
        
        // Let the call run for a while to make sure it is stable
        asyncTaskDone = NO;
        [self waitForCompletion:1 assertOnTimeout:NO];
        XCTAssertTrue([call hasAudio], @"Should indicate the call has audio");
        XCTAssertTrue([call hasVideo], @"Should indicate the call has video");
        
        // Mute the audio & video
        [call muteAudio:YES];
        [call muteVideo:YES];
        asyncTaskDone = NO;
        [self waitForCompletion:1 assertOnTimeout:NO];
        
        XCTAssertTrue(!didHangup, @"Should not have hung up the call yet");
        
        // un-Mute the video
        [call muteVideo:NO];
        asyncTaskDone = NO;
        [self waitForCompletion:1 assertOnTimeout:NO];
        
        XCTAssertTrue(!didHangup, @"Should not have hung up the call yet");
        
        asyncTaskDone = NO;
        [call hangup:YES];
        [self waitForCompletion:1 assertOnTimeout:NO];
        
        XCTAssertTrue(didHangup, @"Should have hung up the call");
    }
}


- (void)testVoiceAnswering
{
    // Create a client to test with
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client, @"Should create test client");
    [client setBaseURL:TEST_RESPOKE_BASE_URL];
    
    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    XCTAssertNotNil(testEndpointID, @"Should create test endpoint id");
    
    asyncTaskDone = NO;
    client.delegate = self;
    [client connectWithEndpointID:testEndpointID appID:TEST_APP_ID reconnect:YES initialPresence:nil errorHandler:^(NSString *errorMessage) {
        XCTAssertTrue(NO, @"Should successfully connect. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];

    [self waitForCompletion:TEST_TIMEOUT];

    XCTAssertTrue([client isConnected], @"First client should connect");
    
    
    // If things went well, there should be a web page open on the test host running a Transporter app that is logged in as testbot. It is set up to automatically answer any calls placed to it for testing purposes.


    RespokeEndpoint *testbotEndpoint = [client getEndpointWithID:TEST_BOT_ENDPOINT_ID skipCreate:NO];
    XCTAssertNotNil(testbotEndpoint, @"Should create endpoint instance");
    testbotEndpoint.delegate = self;
    
    // Send a quick message to make sure the test UI is running and produce a meaningful test error message
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    incomingCallReceived = NO;
    didConnect = NO;
    didHangup = NO;
    [testbotEndpoint sendMessage:TEST_BOT_CALL_ME_MESSAGE successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = incomingCallReceived; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(incomingCallReceived, @"Should have received an incoming call signal");
    XCTAssertNotNil(incomingCall, @"Should have created a call object to represent the incoming call");
    XCTAssertTrue(![incomingCall isCaller], @"Should be the recipient of the call, not the caller");
    XCTAssertTrue(testbotEndpoint == [incomingCall getRemoteEndpoint], @"Should indicate call is with the endpoint that the call was started from");

    asyncTaskDone = NO;
    incomingCall.delegate = self;
    [incomingCall answer];
    [self waitForCompletion:CALL_TEST_TIMEOUT];
    XCTAssertTrue(didConnect, @"Call should be established");
    XCTAssertTrue(incomingCall.audioOnly, @"Should indicate this is an audio-only call");
        
    // Let the call run for a while to make sure it is stable
    asyncTaskDone = NO;
    [self waitForCompletion:1 assertOnTimeout:NO];
    XCTAssertTrue([incomingCall hasAudio], @"Should indicate the call has audio");
    XCTAssertTrue(![incomingCall hasVideo], @"Should indicate the call does not have video");


    // Send a message to the testbot asking it to hangup the call so that we can test detecting that event
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [testbotEndpoint sendMessage:TEST_BOT_HANGUP_MESSAGE successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = didHangup; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(didHangup, @"Should have hung up");
}


- (void)testVideoAnswering
{
    // Create a client to test with
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client, @"Should create test client");
    [client setBaseURL:TEST_RESPOKE_BASE_URL];
    
    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    XCTAssertNotNil(testEndpointID, @"Should create test endpoint id");
    
    asyncTaskDone = NO;
    client.delegate = self;
    [client connectWithEndpointID:testEndpointID appID:TEST_APP_ID reconnect:YES initialPresence:nil errorHandler:^(NSString *errorMessage) {
        XCTAssertTrue(NO, @"Should successfully connect. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    
    XCTAssertTrue([client isConnected], @"First client should connect");
    
    
    // If things went well, there should be a web page open on the test host running a Transporter app that is logged in as testbot. It is set up to automatically answer any calls placed to it for testing purposes.
    
    
    RespokeEndpoint *testbotEndpoint = [client getEndpointWithID:TEST_BOT_ENDPOINT_ID skipCreate:NO];
    XCTAssertNotNil(testbotEndpoint, @"Should create endpoint instance");
    testbotEndpoint.delegate = self;
    
    // Send a quick message to make sure the test UI is running and produce a meaningful test error message
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    incomingCallReceived = NO;
    didConnect = NO;
    didHangup = NO;
    [testbotEndpoint sendMessage:TEST_BOT_CALL_ME_VIDEO_MESSAGE successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = incomingCallReceived; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(incomingCallReceived, @"Should have received an incoming call signal");
    XCTAssertNotNil(incomingCall, @"Should have created a call object to represent the incoming call");
    XCTAssertTrue(![incomingCall isCaller], @"Should be the recipient of the call, not the caller");
    XCTAssertTrue(testbotEndpoint == [incomingCall getRemoteEndpoint], @"Should indicate call is with the endpoint that the call was started from");
    
    asyncTaskDone = NO;
    incomingCall.delegate = self;
    ViewController *viewController = (ViewController*) ((AppDelegate*) [UIApplication sharedApplication].delegate).window.rootViewController;
    [incomingCall setRemoteView:viewController.remoteView];
    [incomingCall setLocalView:viewController.localView];
    [incomingCall answer];
    [self waitForCompletion:CALL_TEST_TIMEOUT];
    XCTAssertTrue(didConnect, @"Call should be established");
    XCTAssertTrue(!incomingCall.audioOnly, @"Should indicate this is an audio-only call");
    
    // Let the call run for a while to make sure it is stable
    asyncTaskDone = NO;
    [self waitForCompletion:1 assertOnTimeout:NO];
    XCTAssertTrue([incomingCall hasAudio], @"Should indicate the call has audio");
    XCTAssertTrue([incomingCall hasVideo], @"Should indicate the call has video");
    
    
    // Send a message to the testbot asking it to hangup the call so that we can test detecting that event
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [testbotEndpoint sendMessage:TEST_BOT_HANGUP_MESSAGE successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = didHangup; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(didHangup, @"Should have hung up");
}


#pragma mark - RespokeClientDelegate methods


- (void)onConnect:(RespokeClient*)sender
{
    asyncTaskDone = YES;
}


- (void)onDisconnect:(RespokeClient*)sender reconnecting:(BOOL)reconnecting
{
    // Not under test
}


- (void)onError:(NSError *)error fromClient:(RespokeClient*)sender
{
    XCTAssertTrue(NO, @"Should not produce any client errors during endpoint testing");
    asyncTaskDone = YES;
}


- (void)onCall:(RespokeCall*)call sender:(RespokeClient*)sender
{
    incomingCall = call;
    incomingCallReceived = YES;
    asyncTaskDone = callbackDidSucceed;
}


- (void)onIncomingDirectConnection:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    // Not under test
}


#pragma mark - RespokeEndpointDelegate methods


- (void)onMessage:(NSString*)message sender:(RespokeEndpoint*)sender timestamp:(NSDate*)timestamp
{
    testbotIsListening = [message isEqualToString:TEST_BOT_HELLO_REPLY];
    messageReceived = YES;
    asyncTaskDone = callbackDidSucceed; // Only signal the task is done if the other callback has already fired
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    // Not under test
}


#pragma mark - RespokeCallDelegate


- (void)onError:(NSString*)errorMessage sender:(RespokeCall*)sender
{
    XCTAssertTrue(NO, @"Should perform a call without any errors. Error message: %@", errorMessage);
    asyncTaskDone = YES;
}


- (void)onHangup:(RespokeCall*)sender
{
    didHangup = YES;

    if (incomingCall)
    {
        // This is the testVoiceAnswering test, so wait for the callback to succeed
        asyncTaskDone = callbackDidSucceed;
    }
    else
    {
        asyncTaskDone = YES;
    }
}


- (void)onConnected:(RespokeCall*)sender
{
    didConnect = YES;
    asyncTaskDone = YES;
}


- (void)directConnectionAvailable:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    // Not under test
}


@end
