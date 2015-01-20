//
//  RespokeClientTests.m
//  RespokeSDK
//
//  Created by Jason Adams on 1/14/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RespokeClient+private.h"
#import "Respoke+private.h"


@interface RespokeClientTests : XCTestCase {
    BOOL callbackDidSucceed;
}

@end


@implementation RespokeClientTests


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


- (void)testUnconnectedClientBehavior 
{
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client);
    
    XCTAssertFalse([client isConnected], @"Should indicate not connected");
    XCTAssertNil([client getEndpointID], @"Local endpoint should be nil if never connected");
    
    [client joinGroups:@[@"newGroupID"] successHandler:^(NSArray *resultArray){
        XCTAssertTrue(NO, @"Should not call success handler");
    } errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"Can't complete request when not connected. Please reconnect!"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler when not connected");
    callbackDidSucceed = NO;
    
    [client setPresence:@"newPresence" successHandler:^{
        XCTAssertTrue(NO, @"Should not call success handler");
    }errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"Can't complete request when not connected. Please reconnect!"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler when not connected");
    
    // Should behave when calling disconnect on a client that is not connected (i.e. don't crash)
    
    [client disconnect];
    
    XCTAssertNil([client getPresence], @"Should return a nil presence when it has not been set");
}


- (void)testConnectParameterErrorHandling
{
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client);
    
    // Test bad parameters
    
    [client connectWithEndpointID:@"myEndpointID" appID:nil reconnect:false initialPresence:nil errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"AppID and endpointID must be specified"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler");
    callbackDidSucceed = NO;
    
    [client connectWithEndpointID:nil appID:@"anAwesomeAppID" reconnect:false initialPresence:nil errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"AppID and endpointID must be specified"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler");
    callbackDidSucceed = NO;
    
    [client connectWithEndpointID:@"" appID:@"" reconnect:false initialPresence:nil errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"AppID and endpointID must be specified"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler");
    
    
    // Test more bad parameters
    
    
    callbackDidSucceed = NO;
    
    [client connectWithTokenID:nil initialPresence:nil errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"TokenID must be specified"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler");
    callbackDidSucceed = NO;
    
    [client connectWithTokenID:@"" initialPresence:nil errorHandler:^(NSString *errorMessage){
        callbackDidSucceed = YES;
        XCTAssertTrue([errorMessage isEqualToString:@"TokenID must be specified"]);
    }];
    
    XCTAssertTrue(callbackDidSucceed, @"Did not call error handler");
    
    
    // Should fail silently if no error handler is specified (i.e. don't crash)
    
    
    [client connectWithEndpointID:@"myEndpointID" appID:nil reconnect:false initialPresence:nil errorHandler:nil];
    [client connectWithTokenID:@"" initialPresence:nil errorHandler:nil];
}


@end
