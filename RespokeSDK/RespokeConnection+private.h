//
//  RespokeConnection+private.h
//  RespokeSDKBuilder
//
//  Copyright 2015, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import "RespokeConnection.h"
#import "RespokeSignalingChannel.h"


@interface RespokeConnection (private)


/**
 *  Initialize a new connection instance
 *
 *  @param channel The signaling channel to use
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel connectionID:(NSString*)connectionID endpoint:(RespokeEndpoint*)endpoint;


/**
 *  Set the presence value for this connection
 *
 *  @param newPresence The new presence value
 */
- (void)setPresence:(NSObject*)newPresence;


@end
