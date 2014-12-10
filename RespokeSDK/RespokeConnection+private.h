//
//  RespokeConnection+private.h
//  RespokeSDKBuilder
//
//  Created by Jason Adams on 8/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
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
