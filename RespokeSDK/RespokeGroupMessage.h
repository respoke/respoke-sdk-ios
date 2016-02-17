//
//  RespokeGroupMessage.h
//  Respoke SDK
//
//  Copyright 2016, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import <Foundation/Foundation.h>

@class RespokeGroup;
@class RespokeEndpoint;

@interface RespokeGroupMessage : NSObject

@property (readonly) NSString* message;
@property (readonly) RespokeGroup* group;
@property (readonly) RespokeEndpoint* endpoint;
@property (readonly) NSDate* timestamp;

@end
