//
//  Header.h
//  RespokeSDK
//
//  Copyright © 2016 Digium, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RespokeConversationReadStatus;

@interface RespokeConversationReadStatus : NSObject

@property NSString* groupID;
@property NSDate* timestamp;

/**
 *  Initialize a new instance
 *  @return The newly initialized instance
 */
- (instancetype)init:(NSString*)groupID
           timestamp:(NSDate *)convTimestamp;

@end
