//
//  RespokeTestCase.m
//  RespokeSDK
//
//  Created by Jason Adams on 1/20/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import "RespokeTestCase.h"


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


@end
