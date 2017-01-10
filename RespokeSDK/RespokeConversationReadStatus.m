//
//  RespokeConversationReadStatus.m
//  RespokeSDK
//
//  Created by Ken Hunt on 12/13/16.
//  Copyright © 2016 Digium, Inc. All rights reserved.
//


#import "RespokeConversationReadStatus.h"

@implementation RespokeConversationReadStatus {
    NSString *groupID;
    NSDate *timestamp;
}

@synthesize groupID;
@synthesize timestamp;

- (instancetype)init:(NSString *)convGroupID
           timestamp:(NSDate *)convTimestamp {
    
    if (self = [super init]) {
        groupID = convGroupID;
        timestamp = convTimestamp;
    }
    
    return self;
}

@end
