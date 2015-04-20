//
//  RespokeSDKTests.m
//  RespokeSDKTests
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
#import "Respoke+private.h"


@interface RespokeSDKTests : XCTestCase

@end


@implementation RespokeSDKTests


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


- (void)testMakeGUID
{
    NSString *guid1 = [Respoke makeGUID];
    NSString *guid2 = [Respoke makeGUID];
    NSString *guid3 = [Respoke makeGUID];
    NSString *guid4 = [Respoke makeGUID];

    XCTAssertTrue(GUID_STRING_LENGTH == [guid1 length], @"GUIDs should be %d characters", GUID_STRING_LENGTH);
    XCTAssertTrue(GUID_STRING_LENGTH == [guid2 length], @"GUIDs should be %d characters", GUID_STRING_LENGTH);
    XCTAssertTrue(GUID_STRING_LENGTH == [guid3 length], @"GUIDs should be %d characters", GUID_STRING_LENGTH);
    XCTAssertTrue(GUID_STRING_LENGTH == [guid4 length], @"GUIDs should be %d characters", GUID_STRING_LENGTH);
    
    XCTAssertFalse([guid1 isEqualToString:guid2], @"Should create unique GUIDs every time");
    XCTAssertFalse([guid1 isEqualToString:guid3], @"Should create unique GUIDs every time");
    XCTAssertFalse([guid1 isEqualToString:guid4], @"Should create unique GUIDs every time");
    
    XCTAssertFalse([guid2 isEqualToString:guid3], @"Should create unique GUIDs every time");
    XCTAssertFalse([guid2 isEqualToString:guid4], @"Should create unique GUIDs every time");
    
    XCTAssertFalse([guid3 isEqualToString:guid4], @"Should create unique GUIDs every time");
}


@end
