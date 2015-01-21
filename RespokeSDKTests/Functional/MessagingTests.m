//
//  MessagingTests.m
//  RespokeSDK
//
//  Created by Jason Adams on 1/14/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RespokeEndpoint+private.h"
#import "Respoke+private.h"
#import "RespokeClient+private.h"
#import "RespokeTestCase.h"

#define TEST_MESSAGE @"This is a test message!"


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
    RespokeClient *firstClient = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(firstClient, @"Should create test client");
    
    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    XCTAssertNotNil(testEndpointID, @"Should create test endpoint id");
    
    asyncTaskDone = NO;
    firstClient.delegate = self;
    [firstClient connectWithEndpointID:testEndpointID appID:TEST_APP_ID reconnect:YES initialPresence:nil errorHandler:^(NSString *errorMessage) {
        XCTAssertTrue(NO, @"Should successfully connect");
    }];

    [self waitForCompletion:TEST_TIMEOUT];

    XCTAssertTrue([firstClient isConnected], @"First client should connect");
    
    
    // Create a second client to test with
    RespokeClient *secondClient = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(secondClient, @"Should create test client");
    
    NSString *secondTestEndpointID = [RespokeTestCase generateTestEndpointID];
    XCTAssertNotNil(secondTestEndpointID, @"Should create test endpoint id");
    
    asyncTaskDone = NO;
    secondClient.delegate = self;
    [secondClient connectWithEndpointID:secondTestEndpointID appID:TEST_APP_ID reconnect:YES initialPresence:nil errorHandler:^(NSString *errorMessage) {
        XCTAssertTrue(NO, @"Should successfully connect");
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    
    XCTAssertTrue([secondClient isConnected], @"Second client should connect");
    
    
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
        XCTAssertTrue(NO, @"Should successfully send a message");
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
