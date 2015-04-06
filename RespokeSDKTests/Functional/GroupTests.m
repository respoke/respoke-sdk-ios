//
//  GroupTests.m
//  RespokeSDK
//
//  Created by Jason Adams on 1/23/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import "RespokeTestCase.h"
#import "RespokeClient+private.h"
#import "Respoke+private.h"
#import "RespokeGroup+private.h"
#import "RespokeConnection+private.h"
#import "RespokeEndpoint+private.h"

#define TEST_GROUP_MESSAGE @"What is going on in this group?"


@interface GroupTests : RespokeTestCase <RespokeClientDelegate, RespokeGroupDelegate> {
    NSString *firstTestEndpointID;
    NSString *secondTestEndpointID;
    RespokeGroup *firstClientGroup;
    RespokeGroup *secondClientGroup;
    BOOL callbackSucceeded;
    BOOL membershipChanged;
    BOOL messageReceived;
    RespokeEndpoint *secondEndpoint;
}

@end


@implementation GroupTests


- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testGroupMembershipAndMessaging
{
    // Create a client to test with
    firstTestEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *firstClient = [self createTestClientWithEndpointID:firstTestEndpointID delegate:self];
    
    // Create a second client to test with
    secondTestEndpointID = [RespokeTestCase generateTestEndpointID];
    RespokeClient *secondClient = [self createTestClientWithEndpointID:secondTestEndpointID delegate:self];
    

    // Have each client join the same group and discover each other
    
    NSString *testGroupID = [@"group" stringByAppendingString:[RespokeTestCase generateTestEndpointID]];
    
    asyncTaskDone = NO;
    [firstClient joinGroups:@[testGroupID] successHandler:^(NSArray *groups){
        XCTAssertNotNil(groups, @"Group list should not be nil");
        XCTAssertTrue(1 == [groups count], @"There should be 1 group that was joined");
        firstClientGroup = [groups firstObject];
        asyncTaskDone = YES;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully join the test group. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertNotNil(firstClientGroup, @"Group object should have been found");
    XCTAssertTrue([[firstClientGroup getGroupID] isEqualToString:testGroupID], @"Group should have the correct ID");
    XCTAssertTrue([firstClientGroup isJoined], @"Group should indicate that it is currently joined");
    firstClientGroup.delegate = self;
    
    // Get the list of group members while firstClient is the only one there
    
    asyncTaskDone = NO;
    [firstClientGroup getMembersWithSuccessHandler:^(NSArray *memberList){
        XCTAssertNotNil(memberList, @"Member list should not be nil");
        XCTAssertTrue(0 == [memberList count], @"There should be 0 members in the group initially");
        asyncTaskDone = YES;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully get the list of group members. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    
    
    asyncTaskDone = NO;
    callbackSucceeded = NO;
    membershipChanged = NO;
    [secondClient joinGroups:@[testGroupID] successHandler:^(NSArray *groups){
        XCTAssertNotNil(groups, @"Group list should not be nil");
        XCTAssertTrue(1 == [groups count], @"There should be 1 group that was joined");
        secondClientGroup = [groups firstObject];
        callbackSucceeded = YES;
        asyncTaskDone = membershipChanged;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully join the test group. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertNotNil(secondClientGroup, @"Group object should have been found");
    XCTAssertTrue([[secondClientGroup getGroupID] isEqualToString:testGroupID], @"Group should have the correct ID");
    XCTAssertTrue([secondClientGroup isJoined], @"Group should indicate that it is currently joined");
    
    // Get the list of group members now that the second client has joined
    
    asyncTaskDone = NO;
    [firstClientGroup getMembersWithSuccessHandler:^(NSArray *memberList){
        XCTAssertNotNil(memberList, @"Member list should not be nil");
        XCTAssertTrue(1 == [memberList count], @"There should be 1 members in the group initially");
        RespokeConnection *connection = [memberList firstObject];
        XCTAssertNotNil([connection connectionID], @"Connection ID should not be nil");
        secondEndpoint = [connection getEndpoint];
        asyncTaskDone = YES;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully get the list of group members. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertNotNil(secondEndpoint, @"Should have found the endpoint reference to the other client");
    XCTAssertTrue([secondEndpoint.endpointID isEqualToString:secondTestEndpointID], @"Should have the correct endpoint ID");
    
    
    // Test sending and receiving a group message
    
    
    asyncTaskDone = NO;
    callbackSucceeded = NO;
    membershipChanged = NO;
    [secondClientGroup sendMessage:TEST_GROUP_MESSAGE successHandler:^{
        callbackSucceeded = YES;
        asyncTaskDone = messageReceived;
    } errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully send a group message. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(messageReceived, @"Message should be received");
    
    
    // Test receiving a leave notification
    
    
    asyncTaskDone = NO;
    callbackSucceeded = NO;
    membershipChanged = NO;
    [secondClientGroup leaveWithSuccessHandler:^{
        callbackSucceeded = YES;
        asyncTaskDone = membershipChanged;
    }errorHandler:^(NSString *errorMessage){
        XCTAssertTrue(NO, @"Should successfully leave a group. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];
    
    [self waitForCompletion:TEST_TIMEOUT];
    XCTAssertTrue(membershipChanged, @"Leave notification should have been received");
    XCTAssertTrue(![secondClientGroup isJoined], @"Should indicate group is no longer joined");
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


#pragma mark - RespokeGroupDelegate methods


- (void)onJoin:(RespokeConnection*)connection sender:(RespokeGroup*)sender
{
    XCTAssertTrue(sender == firstClientGroup, @"Sender should be correct");
    XCTAssertNotNil(connection, @"Connection should not be nil");
    XCTAssertTrue([[[connection getEndpoint] endpointID] isEqualToString:secondTestEndpointID], @"Connection should be associated with the correct endpoint ID");
    membershipChanged = YES;
    asyncTaskDone = callbackSucceeded;
}


- (void)onLeave:(RespokeConnection*)connection sender:(RespokeGroup*)sender
{
    XCTAssertTrue(sender == firstClientGroup, @"Sender should be correct");
    XCTAssertNotNil(connection, @"Connection should not be nil");
    XCTAssertTrue([[[connection getEndpoint] endpointID] isEqualToString:secondTestEndpointID], @"Connection should be associated with the correct endpoint ID");
    membershipChanged = YES;
    asyncTaskDone = callbackSucceeded;
}


- (void)onGroupMessage:(NSString*)message fromEndpoint:(RespokeEndpoint*)endpoint sender:(RespokeGroup*)sender timestamp:(NSDate*)timestamp
{
    XCTAssertNotNil(message, @"Message should not be nil");
    XCTAssertNotNil(timestamp, @"Should include a timestamp");
    XCTAssertTrue((fabs([[NSDate date] timeIntervalSinceDate:timestamp]) < TEST_TIMEOUT), @"Timestamp should be a reasonable value");
    XCTAssertTrue([message isEqualToString:TEST_GROUP_MESSAGE], @"Message should be correct");
    XCTAssertTrue(endpoint == secondEndpoint, @"Should reference the same endpoint object that sent the message");
    XCTAssertTrue(sender == firstClientGroup, @"Should reference the correct group object");
    messageReceived = YES;
    asyncTaskDone = callbackSucceeded;
}


@end
