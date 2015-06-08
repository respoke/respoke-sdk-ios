//
//  Respoke+private.h
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
 *
 */
- (void)client:(RespokeClient*)client connectedWithEndpoint:(NSString*)endpointID;


/**
 *  Attempt to register push services for this device
 */
- (void)registerPushServices;


@end
