//
//  RespokeConnection.h
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

#import <Foundation/Foundation.h>

@class RespokeEndpoint;


/**
 *  Represents remote Connections which belong to an Endpoint. An Endpoint can be authenticated from multiple devices,
 *  browsers, or tabs. Each of these separate authentications is a Connection. The client can interact
 *  with connections by calling them or sending them messages.
 */
@interface RespokeConnection : NSObject


/**
 *  The ID of this connection
 */
@property (readonly) NSString *connectionID;


/**
 *  Get the Endpoint that this Connection belongs to.
 *
 *  @return The endpoint
 */
- (RespokeEndpoint*)getEndpoint;


/**
 *  Get the current presence of this connection
 *
 *  @return The current presence value
 */
- (NSObject*)getPresence;


@end
