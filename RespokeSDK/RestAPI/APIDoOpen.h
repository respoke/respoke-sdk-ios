//
//  APIDoOpen.h
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
