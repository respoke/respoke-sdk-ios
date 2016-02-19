//
//  RespokeGroupMessage.m
//  Respoke SDK
//
//  Copyright 2016, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import "RespokeGroupMessage+private.h"

@interface RespokeGroupMessage () {
    NSString* message;
    RespokeGroup* group;
    RespokeEndpoint* endpoint;
    NSDate* timestamp;
}

@end

@implementation RespokeGroupMessage

@synthesize endpoint;
@synthesize message;
@synthesize group;
@synthesize timestamp;

- (instancetype) initWithMessage:(NSString*)aMessage group:(RespokeGroup*)aGroup
                        endpoint:(RespokeEndpoint*)aEndpoint timestamp:(NSDate*)aTimestamp
{
    if (self = [super init])
    {
        message = aMessage;
        group = aGroup;
        endpoint = aEndpoint;
        timestamp = aTimestamp;
    }

    return self;
}

@end
