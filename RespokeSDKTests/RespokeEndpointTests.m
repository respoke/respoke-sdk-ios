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


@interface RespokeEndpointTests : XCTestCase {
    BOOL callbackDidSucceed;
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
        XCTAssert(@"Should not call success handler");
    } errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"Can't complete request when not connected. Please reconnect!"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler when not connected");
    
    XCTAssertNil([endpoint startVideoCallWithDelegate:nil remoteVideoView:nil localVideoView:nil], @"Should not create a call object when not connected");
    XCTAssertNil([endpoint startAudioCallWithDelegate:nil], @"Should not create a call object when not connected");
}


@end
