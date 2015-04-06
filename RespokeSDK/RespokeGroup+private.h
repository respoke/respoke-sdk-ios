//
//  RespokeGroup+private.h
//  Respoke SDK
//
//  Created by Jason Adams on 7/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "RespokeGroup.h"
#import "RespokeSignalingChannel.h"


@class RespokeClient;


@interface RespokeGroup (private)


/**
 *  Initialize a new group instance
 *
 *  @param groupID  The ID of the group
 *  @param token    The application token
 *  @param channel  The signaling channel to use
 *  @param client   The client managing this group
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithGroupID:(NSString*)groupID appToken:(NSString*)token signalingChannel:(RespokeSignalingChannel*)channel client:(RespokeClient*)newClient;


/**
 *  Notify the group that a connection has joined
 *
 *  @param connection The connection that has joined the group
 */
- (void)connectionDidJoin:(RespokeConnection*)connection;


/**
 *  Notify the group that a connection has left
 *
 *  @param connection The connection that has left the group
 */
- (void)connectionDidLeave:(RespokeConnection*)connection;


/**
 *  Notify the group that a group message was received
 *
 *  @param message      The body of the message
 *  @param endpoint     The endpoint that sent the message
 *  @param timestamp    The message timestamp
 */
- (void)didReceiveMessage:(NSString*)message fromEndpoint:(RespokeEndpoint*)endpoint withTimestamp:(NSDate*)timestamp;


@end