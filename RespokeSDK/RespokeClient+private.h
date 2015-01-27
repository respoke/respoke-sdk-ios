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


@end