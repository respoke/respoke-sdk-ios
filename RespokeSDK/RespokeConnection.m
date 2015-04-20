//
//  RespokeConnection.m
//  Respoke SDK
//
//  Copyright 2015, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import "RespokeConnection+private.h"


@implementation RespokeConnection {
    RespokeSignalingChannel *signalingChannel;  ///< The signaling channel to use
    NSString *connectionID;  ///< The ID of this connection
    RespokeEndpoint __weak *endpoint;  ///< The endpoint to which this connection belongs
    NSObject *presence;  ///< The current presence of this connection
}

@synthesize connectionID;


- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel connectionID:(NSString*)newConnectionID endpoint:(RespokeEndpoint*)newEndpoint
{
    if (self = [super init])
    {
        signalingChannel = channel;
        connectionID = newConnectionID;
        endpoint = newEndpoint;
    }
    
    return self;
}


- (RespokeEndpoint*)getEndpoint
{
    return endpoint;
}


- (void)setPresence:(NSObject*)newPresence
{
    presence = newPresence;
}


- (NSObject*)getPresence
{
    return [presence copy];
}


@end
