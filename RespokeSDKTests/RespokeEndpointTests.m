//
//  RespokeEndpointTests.m
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


@interface RespokeEndpointTests : RespokeTestCase <RespokeClientDelegate, RespokeEndpointDelegate> {
    BOOL callbackDidSucceed;
    BOOL messageReceived;
    RespokeEndpoint *firstEndpoint;
    RespokeEndpoint *secondEndpoint;
}

@end


@implementation RespokeEndpointTests


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


- (void)testUnconnectedEndpointBehavior
{
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client);
    
    XCTAssertNil([client getEndpointWithID:@"someEndpointID" skipCreate:YES], @"Should return nil if no endpoint exists");
    
    RespokeEndpoint *endpoint = [client getEndpointWithID:@"someEndpointID" skipCreate:NO];
    XCTAssertNotNil(endpoint, @"Should create an endpoint instance if it does not exist and it so commanded to");
    XCTAssertTrue([@"someEndpointID" isEqualToString:[endpoint endpointID]], @"Should have the correct endpoint ID");
    
    NSArray *connections = [endpoint connections];
    XCTAssertNotNil(connections, @"Should return an empty list of connections when not connected");
    XCTAssertTrue(0 == [connections count], @"Should return an empty list of connections when not connected");
    
    NSMutableArray *mutableConnections = [endpoint getMutableConnections];
    XCTAssertNotNil(mutableConnections, @"Should return an empty list of connections when not connected");
    XCTAssertTrue(0 == [mutableConnections count], @"Should return an empty list of connections when not connected");
    
    [endpoint sendMessage:@"Hi there!" successHandler:^{
        XCTAssertTrue(NO, @"Should not call success handler");
    } errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"Can't complete request when not connected. Please reconnect!"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler when not connected");
    
    XCTAssertNil([endpoint startVideoCallWithDelegate:nil remoteVideoView:nil localVideoView:nil], @"Should not create a call object when not connected");
    XCTAssertNil([endpoint startAudioCallWithDelegate:nil], @"Should not create a call object when not connected");
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

}


- (void)onError:(NSError *)error fromClient:(RespokeClient*)sender
{
    XCTAssert(@"Should not produce any client errors during endpoint testing");
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
    messageReceived = YES;
    asyncTaskDone = YES;
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    // Not under test
}


@end
