//
//  ConnectionDisconnectTests.m
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

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RespokeEndpoint+private.h"
#import "Respoke+private.h"
#import "RespokeClient+private.h"
#import "RespokeTestCase.h"
#import "RespokeGroup+private.h"
#import "RespokeConnection+private.h"
#import "RespokeGroupMessage.h"


@interface ConnectionDisconnectTests : RespokeTestCase <RespokeClientDelegate, RespokeEndpointDelegate, RespokeGroupDelegate> {
    RespokeGroup *firstClientGroup;
    BOOL callbackDidSucceed;
    BOOL doCopySelf;
    RespokeEndpoint *recipientEndpoint;
    RespokeEndpoint *senderEndpoint;
}

@end


@implementation ConnectionDisconnectTests

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
 *  This test should confirm that an error is thrown when sending an endpoint message when in the process of reconnecting
 */
- (void)testErrorWhenReconnectingEndpointMessage
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
    
    // diconnect and immediately reconnect
    [senderClient disconnect];
    
    // message should error out
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [recipientEndpoint sendMessage:TEST_MESSAGE push:NO ccSelf:NO successHandler:^{
        callbackDidSucceed = NO;
        asyncTaskDone = YES;
        XCTAssertTrue(NO, @"Should not successfully send a message.");
    } errorHandler:^(NSString *errorMessage){
        NSLog(@"Error Message: %@", errorMessage);
        callbackDidSucceed = YES;
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
}

/**
 *  This test should confirm that an error is thrown when sending a group message when in the process of reconnecting
 */
- (void)testErrorWhenReconnectingGroupMessage
{
    // Create a client to test with
    NSString *recipientEndpointID = [RespokeTestCase generateTestEndpointID];
    
    // Create a second client to test with
    NSString *senderEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *senderClient = [self createTestClientWithEndpointID:senderEndpointID delegate:self];
    
    // Join Group
    asyncTaskDone = NO;
    NSString *testGroupID = [@"group" stringByAppendingString:recipientEndpointID];
    [senderClient joinGroups:@[testGroupID] successHandler:^(NSArray *groups){
        firstClientGroup = [groups firstObject];
        asyncTaskDone = YES;
    } errorHandler:^(NSString *errorMessage){
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    
    // diconnect and immediately reconnect
    [senderClient disconnect];
    [self createTestClientWithEndpointID:senderEndpointID delegate:self];
    

    // message should error out
    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [firstClientGroup sendMessage:TEST_MESSAGE push:NO persist:NO successHandler:^{
        callbackDidSucceed = NO;
        asyncTaskDone = YES;
        XCTAssertTrue(NO, @"Should not successfully send a group message.");
    } errorHandler:^(NSString *errorMessage){
        NSLog(@"Error Message: %@", errorMessage);
        callbackDidSucceed = YES;
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(callbackDidSucceed, @"sendMessage should call successHandler");
}

/**
 *  This test should confirm that a null object is returned when executing getGroupWithID to create a RespokeGroup from a group Id String
 */
- (void)testErrorWhenReconnectingGroupMessageGetGroupWithID
{
    // Create a client to test with
    NSString *recipientEndpointID = [RespokeTestCase generateTestEndpointID];
    
    // Create a second client to test with
    NSString *senderEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *senderClient = [self createTestClientWithEndpointID:senderEndpointID delegate:self];
    
    // Join Group
    asyncTaskDone = NO;
    NSString *testGroupID = [@"group" stringByAppendingString:recipientEndpointID];
    [senderClient joinGroups:@[testGroupID] successHandler:^(NSArray *groups){
        firstClientGroup = [groups firstObject];
        asyncTaskDone = YES;
    } errorHandler:^(NSString *errorMessage){
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];

    // diconnect and immediately reconnect
    [senderClient disconnect];
    [self createTestClientWithEndpointID:senderEndpointID delegate:self];
    
    RespokeGroup *respokeGroup = [senderClient getGroupWithID:testGroupID];
    XCTAssertNil(respokeGroup, @"Should be a null value");
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
    // Not under test
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    // Not under test
}

- (void)onJoin:(RespokeConnection*)connection sender:(RespokeGroup*)sender
{
    // Not under test
}


- (void)onLeave:(RespokeConnection*)connection sender:(RespokeGroup*)sender
{
    // Not under test
}


- (void)onGroupMessage:(NSString*)message fromEndpoint:(RespokeEndpoint*)endpoint sender:(RespokeGroup*)sender timestamp:(NSDate*)timestamp
{
    // Not under test
}


@end