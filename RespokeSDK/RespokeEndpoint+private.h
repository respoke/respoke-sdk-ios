//
//  RespokeEndpoint+private.h
//  Respoke SDK
//
//  Created by Jason Adams on 7/14/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "RespokeEndpoint.h"
#import "RespokeSignalingChannel.h"
#import "RespokeClient+private.h"


@interface RespokeEndpoint (private)


/**
 *  Initialize a new endpoint instance
 *
 *  @param channel The signaling channel to use
 *  @param client  The client to which the endpoint belongs
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel endpointID:(NSString*)newEndpointID client:(RespokeClient*)newClient;


/**
 *  Expose the mutable version of the connections list to the rest of the SDK
 *
 *  @return The mutable connections list for this endpoint
 */
- (NSMutableArray*)getMutableConnections;


/**
 *  Process a received message
 *
 *  @param message The body of the message
 *  @param timestamp The message timestamp
 */
- (void)didReceiveMessage:(NSString*)message withTimestamp:(NSDate*)timestamp;


/**
 *  Set the presence value for this endpoint
 *
 *  @param newPresence The new presence value
 */
- (void)setPresence:(NSObject*)newPresence;


/**
 *  Find the presence out of all known connections with the highest priority (most availability)
 *  and set it as the endpoint's resolved presence.
 */
- (void)resolvePresence;


/**
 *  Associate a direct connection object with this endpoint
 *
 *  @param newDirectConnection  The direct connection to associate
 */
- (void)setDirectConnection:(RespokeDirectConnection*)newDirectConnection;


@end