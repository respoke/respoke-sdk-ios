//
//  APIGetToken.h
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
