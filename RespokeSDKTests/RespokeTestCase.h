//
//  RespokeTestCase.h
//  RespokeSDK
//
//  Created by Jason Adams on 1/20/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RespokeClient+private.h"

#define TEST_RESPOKE_BASE_URL @"https://api-int.respoke.io"
#define TEST_APP_ID @"a8c5a9ea-1bab-4353-b8e9-b743bde220f9" // integration
#define TEST_TIMEOUT 30 // timeout in seconds
#define CALL_TEST_TIMEOUT 60 // timeout in seconds for calling tests (which take longer to setup)
#define TEST_BOT_ENDPOINT_ID [NSString stringWithFormat:@"testbot-%@", [[NSProcessInfo processInfo] environment][@"TEST_BOT_SUFFIX"]]
#define TEST_MESSAGE @"This is a test message!"

@interface RespokeTestCase : XCTestCase {
    BOOL asyncTaskDone;
}

+ (NSString*)generateTestEndpointID;
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs assertOnTimeout:(BOOL)assertOnTimeout;
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs;
- (RespokeClient*)createTestClientWithEndpointID:(NSString*)endpointID delegate:(id <RespokeClientDelegate>)delegate;

@end
