//
//  DirectConnectionTests.m
//  RespokeSDK
//
//  Copyright 2015, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import "RespokeTestCase.h"
#import "RespokeEndpoint+private.h"
#import "RespokeCall+private.h"
#import "RespokeDirectConnection+private.h"


@interface DirectConnectionTests : RespokeTestCase <RespokeClientDelegate, RespokeEndpointDelegate, RespokeCallDelegate, RespokeDirectConnectionDelegate> {
    BOOL callbackDidSucceed;
    BOOL messageReceived;
    BOOL didConnect;
    BOOL didHangup;
    BOOL didGetIncomingDirectConnection;
    BOOL didGetCallerOnOpen;
    BOOL didGetCalleeOnOpen;
    BOOL didGetCallerOnClose;
    BOOL didGetCalleeOnClose;
    RespokeEndpoint *firstEndpoint;
    RespokeEndpoint *secondEndpoint;
    RespokeDirectConnection *callerDirectConnection;
    RespokeDirectConnection *calleeDirectConnection;
    id receivedMessageObject;
}

@end


@implementation DirectConnectionTests


- (void)testDirectConnection 
{
    // Create a client to test with
    NSString *firstTestEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *firstClient = [self createTestClientWithEndpointID:firstTestEndpointID delegate:self];
    
    // Create a second client to test with
    NSString *secondTestEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *secondClient = [self createTestClientWithEndpointID:secondTestEndpointID delegate:self];
    
    // Build references to each of the endpoints
    firstEndpoint = [secondClient getEndpointWithID:firstTestEndpointID skipCreate:NO];
    XCTAssertNotNil(firstEndpoint, @"Should create endpoint instance");
    firstEndpoint.delegate = self;
    
    secondEndpoint = [firstClient getEndpointWithID:secondTestEndpointID skipCreate:NO];
    XCTAssertNotNil(secondEndpoint, @"Should create endpoint instance");
    secondEndpoint.delegate = self;

    // Start a direct connection between the two endpoints, calling from firstEndpoint
    asyncTaskDone = NO;
    didGetIncomingDirectConnection = NO;
    didGetCallerOnOpen = NO;
    didGetCalleeOnOpen = NO;
    callerDirectConnection = [secondEndpoint startDirectConnection];
    callerDirectConnection.delegate = self;

    RespokeCall *call = [callerDirectConnection getCall];
    call.delegate = self;
    
    [self waitForCompletion:CALL_TEST_TIMEOUT];
    XCTAssertTrue(didConnect, @"Call should be established");
    XCTAssertTrue(didGetIncomingDirectConnection, @"Callee client should have received an incoming direct connection notification");
    XCTAssertTrue(didGetCallerOnOpen, @"Caller should have received an onOpen notification");
    XCTAssertTrue(didGetCalleeOnOpen, @"Callee should also have received an onOpen notification");
    XCTAssertTrue([call isCaller], @"Call should indicate that it is the caller");
    XCTAssertTrue(secondEndpoint == [call getRemoteEndpoint], @"Should indicate call is with the endpoint that the call was started from");
    XCTAssertNotNil(calleeDirectConnection, @"Callee should have been notified about the incoming direct connection");

    // Test sending a text message over the direct connection
     
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    messageReceived = NO;
    [callerDirectConnection sendMessage:TEST_MESSAGE successHandler:^(void){
        callbackDidSucceed = YES;
        asyncTaskDone = messageReceived;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should not encounter an error when sending a message over a direct connection. Error: %@", errorMessage);
        asyncTaskDone = YES;
    }];

    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should have called the successHandler");
    XCTAssertTrue([receivedMessageObject isKindOfClass:[NSString class]], @"Received message should be a string");
    XCTAssertTrue([((NSString*)receivedMessageObject) isEqualToString:TEST_MESSAGE], @"Should have received correct message");
    
    asyncTaskDone = NO;
    didGetCallerOnClose = NO;
    didGetCalleeOnClose = NO;
    didHangup = NO;
    [call hangup:YES];
    [self waitForCompletion:TEST_TIMEOUT];
    
    XCTAssertTrue(didHangup, @"Should have hung up the call");
    XCTAssertTrue(didGetCalleeOnClose, @"Callee should have received onClose notification");
    XCTAssertTrue(didGetCallerOnClose, @"Caller should have received onClose notification");
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
    XCTAssertTrue(NO, @"Should not produce any client errors during testing");
    asyncTaskDone = YES;
}


- (void)onCall:(RespokeCall*)call sender:(RespokeClient*)sender
{
    // Not under test
}


- (void)onIncomingDirectConnection:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    XCTAssertTrue(endpoint == firstEndpoint, @"Should originate from the first Endpoint");
    XCTAssertNotNil(directConnection, @"DirectConnection object should not be nil");
    calleeDirectConnection = directConnection;
    calleeDirectConnection.delegate = self;
    didGetIncomingDirectConnection = YES;
    
    // Accept the call to continue the connection process
    [directConnection accept];
    
    asyncTaskDone = didConnect && didGetCallerOnOpen && didGetCalleeOnOpen;
}


#pragma mark - RespokeEndpointDelegate methods


- (void)onMessage:(NSString*)message sender:(RespokeEndpoint*)sender timestamp:(NSDate*)timestamp
{
    XCTAssertTrue(NO, @"No messages should have been received through the Respoke service");
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    // Not under test
}


#pragma mark - RespokeCallDelegate methods


- (void)onError:(NSString*)errorMessage sender:(RespokeCall*)sender
{
    XCTAssertTrue(NO, @"Should perform a call without any errors. Error message: %@", errorMessage);
    asyncTaskDone = YES;
}


- (void)onHangup:(RespokeCall*)sender
{
    didHangup = YES;
    asyncTaskDone = didGetCallerOnClose && didGetCalleeOnClose;
}


- (void)onConnected:(RespokeCall*)sender
{
    didConnect = YES;
    asyncTaskDone = didGetIncomingDirectConnection && didGetCallerOnOpen && didGetCalleeOnOpen;
}


- (void)directConnectionAvailable:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    XCTAssertTrue(directConnection == callerDirectConnection, @"Should reference correct direct connection object");
    XCTAssertTrue(endpoint == secondEndpoint, @"Should reference correct remote endpoint");
}


#pragma mark - RespokeDirectConnectionDelegate methods


- (void)onStart:(RespokeDirectConnection*)sender
{
    // This callback will not be called in this test. It is only triggered when adding a directConnection to an existing call, which is currently not supported.
}


- (void)onOpen:(RespokeDirectConnection*)sender
{
    if (sender == callerDirectConnection)
    {
        didGetCallerOnOpen = YES;
    }
    else if (sender == calleeDirectConnection)
    {
        didGetCalleeOnOpen = YES;
    }
    else
    {
        XCTAssertTrue(NO, @"Should reference the correct direct connection object");
    }
    
    asyncTaskDone = didGetIncomingDirectConnection && didConnect && didGetCallerOnOpen && didGetCalleeOnOpen;
}


- (void)onClose:(RespokeDirectConnection*)sender
{
    if (sender == callerDirectConnection)
    {
        didGetCallerOnClose = YES;
    }
    else if (sender == calleeDirectConnection)
    {
        didGetCalleeOnClose = YES;
    }
    else
    {
        XCTAssertTrue(NO, @"Should reference the correct direct connection object");
    }
    
    asyncTaskDone = didHangup && didGetCallerOnClose && didGetCalleeOnClose;
}


- (void)onMessage:(id)message sender:(RespokeDirectConnection*)sender
{
    XCTAssertTrue(sender == calleeDirectConnection, @"Should reference the correct direct connection object");
    XCTAssertNotNil(message, @"message should not be nil");
    receivedMessageObject = message;
    messageReceived = YES;
    asyncTaskDone = callbackDidSucceed;
}


@end
