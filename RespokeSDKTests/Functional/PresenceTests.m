//
//  PresenceTests.m
//  RespokeSDK
//
//  Created by Jason Adams on 1/22/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import "RespokeTestCase.h"
#import "RespokeEndpoint+private.h"
#import "Respoke+private.h"


@interface PresenceTests : RespokeTestCase <RespokeClientDelegate, RespokeEndpointDelegate, RespokeResolvePresenceDelegate> {
    BOOL callbackDidSucceed;
    BOOL remotePresenceReceived;
    RespokeEndpoint *firstEndpoint;
    RespokeEndpoint *secondEndpoint;
    NSObject *expectedRemotePresence;
    NSObject *customPresenceResolution;
}

@end


@implementation PresenceTests


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


- (void)testCustomResolveMethod 
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

    // The custom resolve function will always return this random string
    customPresenceResolution = [Respoke makeGUID];
    
    secondClient.resolveDelegate = self;
    
    asyncTaskDone = NO;
    remotePresenceReceived = NO;
    callbackDidSucceed = NO;
    [firstEndpoint registerPresenceWithSuccessHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = remotePresenceReceived;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully register to receive presence updates. Error: [%@]", errorMessage);
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    
    
    asyncTaskDone = NO;
    remotePresenceReceived = NO;
    callbackDidSucceed = NO;
    expectedRemotePresence = @{@"presence": @"nacho presence2"};
    [firstClient setPresence:expectedRemotePresence successHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = remotePresenceReceived;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully register to receive presence updates. Error: [%@]", errorMessage);
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    
    XCTAssertTrue([[firstEndpoint getPresence] isKindOfClass:[NSString class]], @"Resolved presence should be a string");
    XCTAssertTrue([(NSString*)customPresenceResolution isEqualToString:(NSString*)[firstEndpoint getPresence]], @"Resolved presence should be correct");
}


- (void)testOfflineEndpointPresence
{
    // Create a client to test with
    NSString *testEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *client = [self createTestClientWithEndpointID:testEndpointID delegate:self];

    // Create a second random endpoint id to test with
    NSString *secondTestEndpointID = [RespokeTestCase generateTestEndpointID];

    // Get an endpoint object to represent the second endpoint which is not online
    RespokeEndpoint *endpoint = [client getEndpointWithID:secondTestEndpointID skipCreate:NO];

    XCTAssertNil([endpoint getPresence], @"Presence should be null if the client has not registered for presence updates yet");

    asyncTaskDone = NO;
    callbackDidSucceed = NO;
    [endpoint registerPresenceWithSuccessHandler:^{
        callbackDidSucceed = YES;
        asyncTaskDone = YES;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully register to receive presence updates. Error: [%@]", errorMessage);
    }];

    [self waitForCompletion:TEST_TIMEOUT];

    XCTAssertTrue(callbackDidSucceed, @"Callback should succeed");
    XCTAssertTrue([[endpoint getPresence] isKindOfClass:[NSString class]], @"Resolved presence should be a string");
    XCTAssertTrue([((NSString*)[endpoint getPresence]) isEqualToString:@"unavailable"], @"Presence should be unavailable");
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
    // Not under test
}


#pragma mark - RespokeEndpointDelegate methods


- (void)onMessage:(NSString*)message sender:(RespokeEndpoint*)sender timestamp:(NSDate*)timestamp
{
    // Not under test
}


- (void)onPresence:(NSObject*)presence sender:(RespokeEndpoint*)sender
{
    XCTAssertNotNil(presence, @"Remote presence should not be nil");
    XCTAssertTrue([presence isKindOfClass:[NSString class]], @"Remote presence should be a string");
    XCTAssertTrue([(NSString*)customPresenceResolution isEqualToString:(NSString*)presence], @"Resolved presence should be correct");
    remotePresenceReceived = YES;
    asyncTaskDone = callbackDidSucceed;
}


#pragma mark - RespokeResolvePresenceDelegate methods


- (NSObject*)resolvePresence:(NSArray*)presenceArray
{
    XCTAssertTrue(1 == [presenceArray count], @"presence array should contain the correct number of values");
    return customPresenceResolution;
}


@end
