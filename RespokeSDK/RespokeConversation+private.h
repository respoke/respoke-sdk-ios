//
//  RespokeConversation_private.h
//  RespokeSDK
//
//  Copyright © 2016 Digium, Inc. All rights reserved.
//

#import "RespokeConversation.h"

@class RespokeGroupMessage;

@interface RespokeConversation (private)

/**
 *  Initialize a new conversation instance
 *
 *  @param 
 *
 *  @return The newly initialized instance
 */
- (instancetype)init:(NSDictionary*)convLatestMessage
    groupID:(NSString *)convGroupId
    sourceID:(NSString *)convSourceId
    unreadCount:(NSInteger)convUnreadCount
    timestamp:(NSDate *)convTimestamp;

@end
