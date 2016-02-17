//
//  RespokeClient+private.h
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

#import "RespokeClient.h"

#define LAST_VALID_PUSH_TOKEN_KEY @"LAST_VALID_PUSH_TOKEN_KEY"
#define LAST_VALID_PUSH_TOKEN_ID_KEY @"LAST_VALID_PUSH_TOKEN_ID_KEY"


@interface RespokeClient (private)


/**
 *  Set the base URL of the Respoke service
 *
 *  @param newBaseURL The URL to use
 */
- (void)setBaseURL:(NSString*)newBaseURL;


/**
 *  Register push services for this client's connection
 *
 *  @param token    The push token to use
 */
- (void)registerPushServicesWithToken:(NSData*)token;


/**
 *  Unregister push services for this client
 */
- (void)unregisterFromPushServicesWithSuccessHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler;


@end
