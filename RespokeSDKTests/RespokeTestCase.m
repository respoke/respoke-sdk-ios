//
//  RespokeTestCase.m
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

#import "RespokeTestCase.h"
#import "Respoke.h"


@implementation RespokeTestCase


+ (NSString*)generateTestEndpointID
{
    NSString *uuid = @"test_user_";
    NSString *chars = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    NSInteger rnd = 0;
    NSInteger r;
    
    for (NSInteger i = 0; i < 6; i += 1)
    {
        if (rnd <= 0x02)
        {
            rnd = 0x2000000 + (arc4random() % 0x1000000) | 0;
        }
        r = rnd & 0xf;
        rnd = rnd >> 4;
        
        uuid = [uuid stringByAppendingString:[chars substringWithRange:NSMakeRange(r, 1)]];
    }
    
    return uuid;
}


- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs
{
    return [self waitForCompletion:timeoutSecs assertOnTimeout:YES];
}


- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs assertOnTimeout:(BOOL)assertOnTimeout
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];

    do
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if ([timeoutDate timeIntervalSinceNow] < 0.0)
        {
            break;
        }
    }
    while (!asyncTaskDone);

    if (assertOnTimeout) 
    {
        XCTAssertTrue(asyncTaskDone, @"TIMEOUT after %0.2f seconds", timeoutSecs);
    }

    return asyncTaskDone;
}


- (RespokeClient*)createTestClientWithEndpointID:(NSString*)endpointID delegate:(id <RespokeClientDelegate>)delegate
{
    RespokeClient *client = [[Respoke sharedInstance] createClient];
    XCTAssertNotNil(client, @"Should create test client");
    [client setBaseURL:TEST_RESPOKE_BASE_URL];
    
    asyncTaskDone = NO;
    client.delegate = delegate;
    [client connectWithEndpointID:endpointID appID:TEST_APP_ID reconnect:YES initialPresence:nil errorHandler:^(NSString *errorMessage) {
        XCTAssertTrue(NO, @"Should successfully connect. Error: [%@]", errorMessage);
        asyncTaskDone = YES;
    }];

    [self waitForCompletion:TEST_TIMEOUT];

    XCTAssertTrue([client isConnected], @"First client should connect");

    return client;
}


@end
