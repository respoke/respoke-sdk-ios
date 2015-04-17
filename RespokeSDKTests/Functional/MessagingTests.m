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
    BOOL messageReceived;
    RespokeEndpoint *firstEndpoint;
    RespokeEndpoint *secondEndpoint;
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
    // Create a client to test with
    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *firstClient = [self createTestClientWithEndpointID:testEndpointID delegate:self];
    
    // Create a second client to test with
    NSString *secondTestEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *secondClient = [self createTestClientWithEndpointID:secondTestEndpointID delegate:self];
    
    // Build references to each of the endpoints
    firstEndpoint = [secondClient getEndpointWithID:testEndpointID skipCreate:NO];
    XCTAssertNotNil(firstEndpoint, @"Should create endpoint instance");
    firstEndpoint.delegate = self;
    
    secondEndpoint = [firstClient getEndpointWithID:secondTestEndpointID skipCreate:NO];
    XCTAssertNotNil(secondEndpoint, @"Should create endpoint instance");
    secondEndpoint.delegate = self;
    
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [firstEndpoint sendMessage:TEST_MESSAGE successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = messageReceived; // If the delegate message fired first, signal the task is done
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a message. Error: [%@]", errorMessage);
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
    XCTAssertTrue(messageReceived, @"Should call onMessage delegate when a message is received");
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


- (void)onMessage:(NSString*)message sender:(RespokeEndpoint*)sender timestamp:(NSDate*)timestamp
{
    XCTAssertTrue([message isEqualToString:TEST_MESSAGE], @"Message sent should be the message received");
    XCTAssertTrue([sender.endpointID isEqualToString:secondEndpoint.endpointID], @"Should indicate correct sender endpoint ID");
    XCTAssertNotNil(timestamp, @"Should include a timestamp");
    XCTAssertTrue((fabs([[NSDate date] timeIntervalSinceDate:timestamp]) < TEST_TIMEOUT), @"Timestamp should be a reasonable value");
    messageReceived = YES;
    asyncTaskDone = callbackDidSucceed; // Only signal the task is done if the other callback has already fired
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    // Not under test
}


@end
