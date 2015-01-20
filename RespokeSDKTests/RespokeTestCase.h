//
//  RespokeTestCase.h
//  RespokeSDK
//
//  Created by Jason Adams on 1/20/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


#define TEST_APP_ID @"57ac5f3a-0513-40b5-ba42-b80939e69436" // integration
#define TEST_TIMEOUT 30 // timeout in seconds


@interface RespokeTestCase : XCTestCase {
    BOOL asyncTaskDone;
}

+ (NSString*)generateTestEndpointID;
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs;

@end
