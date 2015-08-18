//
//  HangupTests.m
//  RespokeSDK
//
//  Created by Rob Crabtree on 8/17/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//


#import "RespokeTestCase.h"
#import "RespokeEndpoint+private.h"
#import "Respoke+private.h"
#import "RespokeCall+private.h"
#import "AppDelegate.h"
#import "ViewController.h"


#define TEST_BOT_CALL_ME_MESSAGE @"Testbot! Call me sometime! Or now!"


@interface HangupTests : RespokeTestCase <RespokeClientDelegate, RespokeEndpointDelegate, RespokeCallDelegate> {
    BOOL callbackDidSucceed;
    BOOL firstCallDidHangup;
    BOOL secondCallDidHangup;
    RespokeCall *firstIncomingCall;
    RespokeCall *secondIncomingCall;
    RespokeEndpoint *testbotEndpoint;
    RespokeClient *firstClient;
    RespokeClient *secondClient;
}

@end


@implementation HangupTests


#pragma mark - RespokeClientDelegate methods


- (void)testCallDeclineCCSelf {

    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    firstClient = [self createTestClientWithEndpointID:testEndpointID delegate:self];
    secondClient = [self createTestClientWithEndpointID:testEndpointID delegate:self];

    // If things went well, there should be a web page open on the test host running a Transporter app that is logged in as testbot. It is set up to automatically initiate a call when asked via Respoke message
    testbotEndpoint = [firstClient getEndpointWithID:TEST_BOT_ENDPOINT_ID skipCreate:NO];
    XCTAssertNotNil(testbotEndpoint, "Should create endpoint instance");
    testbotEndpoint.delegate = self;

    // Send a quick message to make sure the test UI is running and produce a meaningful test error message
    asyncTaskDone = NO;
    callbackDidSucceed = NO;

    [testbotEndpoint sendMessage:TEST_BOT_CALL_ME_MESSAGE push:NO ccSelf:NO successHandler:^{
        callbackDidSucceed = YES;

        if (firstIncomingCall && secondIncomingCall)
        {
            asyncTaskDone = YES;
        }
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];

    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(asyncTaskDone, @"Test timed out");
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call onSuccess");
    XCTAssertNotNil(firstIncomingCall, @"Should have created a call object to represent the incoming call");
    XCTAssertTrue(!firstIncomingCall.isCaller, @"Should be the recipient of the call, not the caller");
    XCTAssertTrue(testbotEndpoint == [firstIncomingCall getRemoteEndpoint], @"Should indicate call is with the endpoint that the call was started from");
    XCTAssertTrue(firstIncomingCall.audioOnly, @"Should indicate this is an audio-only call");
    XCTAssertNotNil(secondIncomingCall, @"Should have created a call object to represent the incoming call");
    XCTAssertTrue(!secondIncomingCall.isCaller, @"Should be the recipient of the call, not the caller");
    XCTAssertTrue([testbotEndpoint.endpointID isEqualToString:[secondIncomingCall getRemoteEndpoint].endpointID], @"Should indicate call is with the endpoint that the call was started from");
    XCTAssertTrue(secondIncomingCall.audioOnly, @"Should indicate this is an audio-only call");

    asyncTaskDone = NO;
    [firstIncomingCall hangup:YES];
    [self waitForCompletion:TEST_TIMEOUT];

    XCTAssertTrue(asyncTaskDone, @"Test timed out");
    XCTAssertTrue(firstCallDidHangup, @"First client should have hung up the call");
    XCTAssertTrue(secondCallDidHangup, @"Second client should have been notified of the hangup");

    [firstClient disconnect];
    [[Respoke sharedInstance] unregisterClient:firstClient];
    [secondClient disconnect];
    [[Respoke sharedInstance] unregisterClient:secondClient];
}


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
    XCTAssertTrue(NO, "Should not produce any client errors during endpoint testing");
    asyncTaskDone = YES;
}


- (void)onCall:(RespokeCall*)call sender:(RespokeClient*)sender
{
    if (sender == firstClient)
    {
        firstIncomingCall = call;
        firstIncomingCall.delegate = self;
    }
    else if (sender == secondClient)
    {
        secondIncomingCall = call;
        secondIncomingCall.delegate = self;
    }
    else
    {
        XCTAssertTrue(NO, "Unrecognized client received an incoming call");
    }

    if (callbackDidSucceed && firstIncomingCall && secondIncomingCall)
    {
        asyncTaskDone = YES;
    }
}


- (void)onIncomingDirectConnection:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    // Not under test
}


#pragma mark - RespokeEndpointDelegate methods


- (void)onMessage:(NSString*)message endpoint:(RespokeEndpoint*)endpoint timestamp:(NSDate*)timestamp didSend:(BOOL)didSend
{
    // Not under test
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    // Not under test
}


#pragma mark - RespokeCallDelegate


- (void)onError:(NSString*)errorMessage sender:(RespokeCall*)sender
{
    XCTAssertTrue(NO, @"Should perform a call without any errors. Error: [%@]", errorMessage);
    asyncTaskDone = YES;
}


- (void)onHangup:(RespokeCall*)sender
{
    if (sender == firstIncomingCall)
    {
        firstCallDidHangup = true;
    }
    else if (sender == secondIncomingCall)
    {
        secondCallDidHangup = true;
    }
    else
    {
        XCTAssertTrue(NO, @"Unrecognized call received a hangup signal");
    }

    if (firstCallDidHangup && secondCallDidHangup)
    {
        asyncTaskDone = YES;
    }
}


- (void)onConnected:(RespokeCall*)sender
{
    // Not under test
}


- (void)directConnectionAvailable:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    // Not under test
}


@end
