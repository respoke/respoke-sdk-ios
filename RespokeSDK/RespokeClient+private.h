//
//  RespokeClient+private.h
//  Respoke SDK
//
//  Created by Jason Adams on 7/11/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "RespokeClient.h"


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


@end