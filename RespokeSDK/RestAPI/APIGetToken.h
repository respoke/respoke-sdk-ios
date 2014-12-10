//
//  APIGetToken.h
//  Respoke SDK
//
//  Created by Jason Adams on 7/11/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "APITransaction.h"


/**
 *  A REST transaction to retrieve an application token ID from the cloud infrastructure
 */
@interface APIGetToken : APITransaction

/**
 *  The application ID to send
 */
@property NSString *appID;


/**
 *  The local endpoint ID to send
 */
@property NSString *endpointID;


/**
 *  The application token ID received from the server
 */
@property NSString *token;


@end
