//
//  APIRegisterPushToken.h
//  RespokeSDKBuilder
//
//  Created by Jason Adams on 11/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "APITransaction.h"

@interface APIRegisterPushToken : APITransaction


/**
 *  The APNS token to send
 */
@property NSData *token;


@property NSArray *endpointIDArray;


@end
