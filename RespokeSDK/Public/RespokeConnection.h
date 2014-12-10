//
//  RespokeConnection.h
//  Respoke SDK
//
//  Created by Jason Adams on 8/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
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
