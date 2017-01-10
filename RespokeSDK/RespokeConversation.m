//
//  RespokeConversation.m
//  RespokeSDK
//
//  Copyright © 2016 Digium, Inc. All rights reserved.
//

#import "RespokeConversation+private.h"
#import "RespokeGroupMessage.h"

@implementation RespokeConversation {
    NSDictionary *latestMessage;
    NSString *groupID;
    NSString *sourceID;
    NSInteger unreadCount;
    NSDate *timestamp;
}

@synthesize latestMessage;
@synthesize groupID;
@synthesize sourceID;
@synthesize unreadCount;
@synthesize timestamp;

- (instancetype)init:(NSDictionary *)convLatestMessage
             groupID:(NSString *)convGroupID
            sourceID:(NSString *)convSourceID
         unreadCount:(NSInteger)convUnreadCount
           timestamp:(NSDate *)convTimestamp {
    
    if (self = [super init]) {
        latestMessage = convLatestMessage;
        groupID = convGroupID;
        sourceID = convSourceID;
        unreadCount = convUnreadCount;
        timestamp = convTimestamp;
    }
    
    return self;
}

@end

