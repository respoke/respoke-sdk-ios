//
//  APIDoOpen.h
//  Respoke SDK
//
//  Created by Jason Adams on 7/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "APITransaction.h"


/**
 *  A REST transaction to open a client connection with the cloud infrastructure
 */
@interface APIDoOpen : APITransaction


/**
 *  The application token ID to send
 */
@property NSString *tokenID;


/**
 *  The returned application token
 */
@property NSString *appToken;


@end
