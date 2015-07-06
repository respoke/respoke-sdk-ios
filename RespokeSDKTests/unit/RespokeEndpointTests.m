//
//  RespokeEndpointTests.m
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
#import "RespokeConnection+private.h"


@interface RespokeEndpointTests : RespokeTestCase <RespokeEndpointDelegate, RespokeResolvePresenceDelegate> {
    BOOL callbackDidSucceed;
    RespokeEndpoint *presenceTestEndpoint;
    NSObject *callbackPresence;
    NSObject *customPresenceResolution;
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
    
    [endpoint sendMessage:@"Hi there!" push:NO ccSelf:NO successHandler:^{
        XCTAssertTrue(NO, @"Should not call success handler");
    } errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"Can't complete request when not connected. Please reconnect!"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler when not connected");
    
    XCTAssertNil([endpoint startVideoCallWithDelegate:nil remoteVideoView:nil localVideoView:nil], @"Should not create a call object when not connected");
    XCTAssertNil([endpoint startAudioCallWithDelegate:nil], @"Should not create a call object when not connected");
}


- (void)testPresence
{
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client);
    
    presenceTestEndpoint = [client getEndpointWithID:@"someEndpointID" skipCreate:NO];
    XCTAssertNotNil(presenceTestEndpoint, @"Should create an endpoint instance if it does not exist and it so commanded to");
    presenceTestEndpoint.delegate = self;
    
    XCTAssertNil([presenceTestEndpoint getPresence], @"Presence should initially be nil");
    
    
    // Test presence with no connections
    
    
    callbackDidSucceed = NO;
    callbackPresence = nil;
    [presenceTestEndpoint resolvePresence];
    XCTAssertTrue(callbackDidSucceed, @"Presence delegate should be called");
    XCTAssertTrue([@"unavailable" isEqualToString:(NSString*)callbackPresence], @"Expected presence to be [%@] but found [%@]", @"unavailable", callbackPresence);
    
    
    // Test presence with one connection
    
    
    RespokeConnection *connection = [[RespokeConnection alloc] initWithSignalingChannel:nil connectionID:[Respoke makeGUID] endpoint:presenceTestEndpoint];
    XCTAssertNotNil(connection, @"Should create connection");
    XCTAssertNil([connection getPresence], @"Presence should initially be nil");
    [[presenceTestEndpoint getMutableConnections] addObject:connection];
    XCTAssertTrue([[presenceTestEndpoint connections] count] == 1, @"Should properly add connection to endpoint");
    
    // Test with a nil presence on the one connection
    callbackDidSucceed = NO;
    callbackPresence = nil;
    [presenceTestEndpoint resolvePresence];
    XCTAssertTrue(callbackDidSucceed, @"Presence delegate should be called");
    XCTAssertTrue([@"unavailable" isEqualToString:(NSString*)[presenceTestEndpoint getPresence]], @"Should use the default presence value");
    
    // Test for the standard presence values
    NSArray *options = @[@"chat", @"available", @"away", @"dnd", @"xa", @"unavailable"];
    for (NSString *eachPresence in options)
    {
        [connection setPresence:eachPresence];
        XCTAssertTrue([eachPresence isEqualToString:(NSString*)[connection getPresence]], @"Presence should be set correctly");
        
        callbackDidSucceed = NO;
        callbackPresence = nil;
        [presenceTestEndpoint resolvePresence];
        XCTAssertTrue(callbackDidSucceed, @"Presence delegate should be called");
        XCTAssertTrue([eachPresence isEqualToString:(NSString*)callbackPresence], @"Expected presence to be [%@] but found [%@]", eachPresence, callbackPresence);
        XCTAssertTrue([eachPresence isEqualToString:(NSString*)[presenceTestEndpoint getPresence]], @"Resolved endpoint presence should match the connections");
    }
    
    
    // Test presence with 2 connections
    
    
    RespokeConnection *secondConnection = [[RespokeConnection alloc] initWithSignalingChannel:nil connectionID:[Respoke makeGUID] endpoint:presenceTestEndpoint];
    XCTAssertNotNil(secondConnection, @"Should create connection");
    XCTAssertNil([secondConnection getPresence], @"Presence should initially be nil");
    [[presenceTestEndpoint getMutableConnections] addObject:secondConnection];
    XCTAssertTrue([[presenceTestEndpoint connections] count] == 2, @"Should properly add connection to endpoint");
    
    for (NSInteger ii = 0; ii < [options count]; ii++)
    {
        NSString *firstPresence = [options objectAtIndex:ii];
        
        for (NSInteger jj = 0; jj < [options count]; jj++)
        {
            NSString *secondPresence = [options objectAtIndex:jj];
            
            [connection setPresence:firstPresence];
            [secondConnection setPresence:secondPresence];
            
            NSString *expectedPresence = nil;
            
            if (ii <= jj)
            {
                expectedPresence = firstPresence;
            }
            else
            {
                expectedPresence = secondPresence;
            }
            
            callbackDidSucceed = NO;
            callbackPresence = nil;
            [presenceTestEndpoint resolvePresence];
            XCTAssertTrue(callbackDidSucceed, @"Presence delegate should be called");
            XCTAssertTrue([expectedPresence isEqualToString:(NSString*)callbackPresence], @"Expected presence to be [%@] but found [%@]", expectedPresence, callbackPresence);
            XCTAssertTrue([expectedPresence isEqualToString:(NSString*)[presenceTestEndpoint getPresence]], @"Resolved endpoint presence should match the connections");
        }
    }
}


- (void)testCustomPresence
{
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client);
    client.resolveDelegate = self;
    
    presenceTestEndpoint = [client getEndpointWithID:@"someEndpointID" skipCreate:NO];
    XCTAssertNotNil(presenceTestEndpoint, @"Should create an endpoint instance if it does not exist and it so commanded to");
    presenceTestEndpoint.delegate = self;
    
    RespokeConnection *connection1 = [[RespokeConnection alloc] initWithSignalingChannel:nil connectionID:[Respoke makeGUID] endpoint:presenceTestEndpoint];
    XCTAssertNotNil(connection1, @"Should create connection");
    [[presenceTestEndpoint getMutableConnections] addObject:connection1];
    
    RespokeConnection *connection2 = [[RespokeConnection alloc] initWithSignalingChannel:nil connectionID:[Respoke makeGUID] endpoint:presenceTestEndpoint];
    XCTAssertNotNil(connection2, @"Should create connection");
    [[presenceTestEndpoint getMutableConnections] addObject:connection2];
    
    RespokeConnection *connection3 = [[RespokeConnection alloc] initWithSignalingChannel:nil connectionID:[Respoke makeGUID] endpoint:presenceTestEndpoint];
    XCTAssertNotNil(connection3, @"Should create connection");
    [[presenceTestEndpoint getMutableConnections] addObject:connection3];
    
    
    // Test presence values that are not strings
    
    
    customPresenceResolution = @{@"myRealPresence": @"ready"};
    
    [connection1 setPresence:@{@"myRealPresence": @"not ready"}];
    [connection2 setPresence:customPresenceResolution];
    [connection3 setPresence:@{@"myRealPresence": @"not ready"}];
    
    callbackDidSucceed = NO;
    callbackPresence = nil;
    [presenceTestEndpoint resolvePresence];
    XCTAssertTrue(callbackDidSucceed, @"Presence delegate should be called");
    XCTAssertTrue([[presenceTestEndpoint getPresence] isKindOfClass:[NSDictionary class]], @"Custom presence should be a dictionary");
    
    XCTAssertTrue([@"ready" isEqualToString:[[presenceTestEndpoint getPresence] valueForKey:@"myRealPresence"]], @"Should resolve to correct custom presence");
    XCTAssertTrue([@"ready" isEqualToString:[callbackPresence valueForKey:@"myRealPresence"]], @"Should resolve to correct custom presence in callback");
}


#pragma mark - RespokeEndpointDelegate methods


- (void)onMessage:(NSString*)message endpoint:(RespokeEndpoint*)endpoint timestamp:(NSDate*)timestamp didSend:(BOOL)didSend
{
    // Not under test
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    XCTAssertTrue(sender == presenceTestEndpoint, @"Sender should be set correctly");
    callbackPresence = presence;
    callbackDidSucceed = YES;
}


#pragma mark - RespokeResolvePresenceDelegate methods


- (NSObject*)resolvePresence:(NSArray*)presenceArray
{
    XCTAssertTrue(3 == [presenceArray count], @"presence array should contain the correct number of values");
    return customPresenceResolution;
}


@end
