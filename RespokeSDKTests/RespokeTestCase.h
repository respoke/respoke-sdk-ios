//
//  RespokeTestCase.h
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

#import <XCTest/XCTest.h>
#import "RespokeClient+private.h"

#define TEST_RESPOKE_BASE_URL @"https://api.respoke.io"
#define TEST_APP_ID @"REPLACE_ME"
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
