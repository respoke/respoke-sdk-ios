//
//  MessagingTests.m
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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RespokeEndpoint+private.h"
#import "Respoke+private.h"
#import "RespokeClient+private.h"
#import "RespokeTestCase.h"


@interface MessagingTests : RespokeTestCase <RespokeClientDelegate, RespokeEndpointDelegate> {
    BOOL callbackDidSucceed;
    BOOL messageDelivered;
    BOOL messageCopied;
    BOOL doCopySelf;
    RespokeEndpoint *recipientEndpoint;
    RespokeEndpoint *senderEndpoint;
}

@end


@implementation MessagingTests


- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    callbackDidSucceed = NO;
}


- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


/**
 *  This test will create two client instances with unique endpoint IDs. It will then send messages between the two to test functionality.
 */
- (void)testEndpointMessaging
{
    doCopySelf = NO;
    [self runMessageTest];
}


/**
 *  This test will create two client instances with unique endpoint IDs. It will then send messages between the two to test functionality.
 */
- (void)testEndpointMessagingCCSelf
{
    doCopySelf = YES;
    [self runMessageTest];
}


- (void)runMessageTest
{

    // Create a client to test with
    NSString *recipientEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *recipientClient = [self createTestClientWithEndpointID:recipientEndpointID delegate:self];

    // Create a second client to test with
    NSString *senderEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *senderClient = [self createTestClientWithEndpointID:senderEndpointID delegate:self];

    // Build references to each of the endpoints
    recipientEndpoint = [senderClient getEndpointWithID:recipientEndpointID skipCreate:NO];
    XCTAssertNotNil(recipientEndpoint, @"Should create endpoint instance");
    recipientEndpoint.delegate = self;

    senderEndpoint = [recipientClient getEndpointWithID:senderEndpointID skipCreate:NO];
    XCTAssertNotNil(senderEndpoint, @"Should create endpoint instance");
    senderEndpoint.delegate = self;

    // Create new client and endpoint for copying self
    if (doCopySelf)
    {
        RespokeClient *senderCCClient = [self createTestClientWithEndpointID:senderEndpointID delegate:self];
        XCTAssertNotNil(senderCCClient, @"Should create sender CC client");

        RespokeEndpoint *recipientCCEndpoint = [senderCCClient getEndpointWithID:recipientEndpointID skipCreate:NO];
        XCTAssertNotNil(recipientCCEndpoint, @"Should create endpoint instance");
        recipientCCEndpoint.delegate = self;
    }

    messageCopied = NO;
    messageDelivered = NO;
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [recipientEndpoint sendMessage:TEST_MESSAGE push:NO ccSelf:doCopySelf successHandler:^{
        callbackDidSucceed = YES;
        [self tryCompleteTask]; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
    }];

    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(messageDelivered, @"Should call onMessage delegate when a message is delivered");

    if (doCopySelf)
    {
        XCTAssertTrue(messageCopied, @"Should call onMessage delegate when a message is copied");
    }
}


- (void)tryCompleteTask
{
    asyncTaskDone = callbackDidSucceed && messageDelivered;
    if (doCopySelf)
    {
        asyncTaskDone = asyncTaskDone && messageCopied;
    }
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
    // Not under test
}


- (void)onIncomingDirectConnection:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    // Not under test
}


#pragma mark - RespokeEndpointDelegate methods


- (void)onMessage:(NSString*)message endpoint:(RespokeEndpoint*)endpoint timestamp:(NSDate*)timestamp didSend:(BOOL)didSend
{
    XCTAssertTrue([message isEqualToString:TEST_MESSAGE], @"Message sent should be the message received");
    XCTAssertNotNil(timestamp, @"Should include a timestamp");
    XCTAssertTrue((fabs([[NSDate date] timeIntervalSinceDate:timestamp]) < TEST_TIMEOUT), @"Timestamp should be a reasonable value");

    if (!doCopySelf)
    {
        XCTAssertTrue(didSend, @"Endoint should always be the sender");
    }

    if (didSend)
    {
        XCTAssertTrue([endpoint.endpointID isEqualToString:senderEndpoint.endpointID], @"Should indicate correct sender endpoint ID");
        messageDelivered = YES;
    }
    else
    {
        XCTAssertTrue([endpoint.endpointID isEqualToString:recipientEndpoint.endpointID], @"Should indicate correct recipient endpoint ID");
        XCTAssertTrue(doCopySelf, @"Endpiont should only be the recipient if ccSelf is enabled");
        messageCopied = YES;
    }

    [self tryCompleteTask];
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    // Not under test
}


@end
