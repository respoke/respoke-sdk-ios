//
//  RespokeGroup+private.h
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

#import "RespokeGroup.h"
#import "RespokeSignalingChannel.h"


@class RespokeClient;


@interface RespokeGroup (private)


/**
 *  Initialize a new group instance. Defaults to setting the group's isJoined to `true`.
 *  To manually specify the `isJoined` param, use the other method signature.
 *
 *  @param groupID  The ID of the group
 *  @param channel  The signaling channel to use
 *  @param client   The client managing this group
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithGroupID:(NSString*)groupID signalingChannel:(RespokeSignalingChannel*)channel
                         client:(RespokeClient*)newClient;

/**
 *  Initialize a new group instance
 *
 *  @param groupID  The ID of the group
 *  @param channel  The signaling channel to use
 *  @param client   The client managing this group
 *  @param isJoined Whether the group has already been joined
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithGroupID:(NSString*)groupID signalingChannel:(RespokeSignalingChannel*)channel
                         client:(RespokeClient*)newClient isJoined:(BOOL)isJoined;


- (BOOL)isConnected;

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
