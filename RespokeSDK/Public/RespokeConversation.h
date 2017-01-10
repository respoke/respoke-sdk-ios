//
//  RespokeConversation.h
//  RespokeSDK
//
//  Copyright © 2016 Digium, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

@class RespokeGroupMessage;

@interface RespokeConversation : NSObject

@property (readonly) NSDictionary* latestMessage;
@property (readonly) NSString* groupID;
@property (readonly) NSString* sourceID;
@property (readonly) NSInteger unreadCount;
@property (readonly) NSDate* timestamp;

@end
