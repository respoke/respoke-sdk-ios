//
//  Respoke+private.h
//  Respoke SDK
//
//  Created by Jason Adams on 7/7/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "Respoke.h"


#define GUID_STRING_LENGTH 36 // The length of GUID strings


@interface Respoke (private)


/**
 *  Create a globally unique identifier for naming instances
 *
 *  @return New globally unique identifier
 */
+ (NSString*)makeGUID;


/**
 *  Inform the Respoke singleton that the specified client is no longer active
 *
 *  @param client  The client to unregister
 */
- (void)unregisterClient:(RespokeClient*)client;


/**
 *
 */
- (void)client:(RespokeClient*)client connectedWithEndpoint:(NSString*)endpointID;


/**
 *  Attempt to register push services for this device
 */
- (void)registerPushServices;


@end
