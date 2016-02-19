//
//  RespokeTests.m
//  RespokeSDK
//
//  Copyright 2016, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import <XCTest/XCTest.h>
#import "Respoke+private.h"

@interface RespokeTests : XCTestCase

@end


@implementation RespokeTests


- (void) testbuildQueryWithComponents
{
    NSString* handlesSimpleQuery = [[Respoke sharedInstance] buildQueryWithComponents:@{
        @"foo": @"bar",
        @"bar": @"baz"
    }];

    XCTAssertEqualObjects(handlesSimpleQuery, @"?foo=bar&bar=baz");

    NSString* handlesQueryNeedingEscape = [[Respoke sharedInstance] buildQueryWithComponents:@{
        @"foo": @"ba&r",
        @"b&r": @"b#z"
    }];

    XCTAssertEqualObjects(handlesQueryNeedingEscape, @"?foo=ba%26r&b%26r=b%23z");

    NSString* handlesArrayInValue = [[Respoke sharedInstance] buildQueryWithComponents:@{
        @"foo": @"bar",
        @"b&r": @[ @1, @2, @3, @4]
    }];

    XCTAssertEqualObjects(handlesArrayInValue, @"?foo=bar&b%26r=1&b%26r=2&b%26r=3&b%26r=4");
}

@end
