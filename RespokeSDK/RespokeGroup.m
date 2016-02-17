//
//  RespokeGroup.m
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

#import "RespokeGroup+private.h"
#import "RespokeEndpoint+private.h"
#import "RespokeClient+private.h"
#import "RespokeConnection+private.h"
#import "Respoke.h"
#import "Respoke+private.h"


@interface RespokeGroup () {
    NSString *groupID;  ///< The ID of this group
    RespokeClient __weak *client;  ///< The client managing this group
    RespokeSignalingChannel *signalingChannel;  ///< The signaling channel to use
    NSMutableArray *members;  ///< An array of the members of this group
    BOOL joined;  ///< Indicates if the client is a member of this group
}

@end


@implementation RespokeGroup


- (instancetype)initWithGroupID:(NSString*)newGroupID signalingChannel:(RespokeSignalingChannel*)channel
                         client:(RespokeClient*)newClient
{
    return [self initWithGroupID:newGroupID signalingChannel:channel client:newClient isJoined:YES];
}


- (instancetype)initWithGroupID:(NSString *)newGroupID signalingChannel:(RespokeSignalingChannel *)channel
                         client:(RespokeClient *)newClient isJoined:(BOOL)isJoined
{
    if (self = [super init])
    {
        groupID = newGroupID;
        signalingChannel = channel;
        client = newClient;
        members = [[NSMutableArray alloc] init];
        joined = isJoined;
    }

    return self;
}


- (void)getMembersWithSuccessHandler:(void (^)(NSArray*))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if ([self isJoined])
    {
        if ([groupID length])
        {
            NSString* encodedGroupID = [[Respoke sharedInstance] encodeURIComponent:groupID];
            NSString *urlEndpoint = [NSString stringWithFormat:@"/v1/groups/%@", encodedGroupID];

            [signalingChannel sendRESTMessage:@"get" url:urlEndpoint data:nil responseHandler:^(id response, NSString *errorMessage) {
                if (errorMessage)
                {
                    errorHandler(errorMessage);
                }
                else
                {
                    if ([response isKindOfClass:[NSArray class]])
                    {
                        NSMutableArray *nameList = [[NSMutableArray alloc] init];

                        for (NSDictionary *eachEntry in response)
                        {
                            NSString *newEndpointID = [eachEntry objectForKey:@"endpointId"];
                            NSString *newConnectionID = [eachEntry objectForKey:@"connectionId"];

                            // Do not include ourselves in this list
                            if (![newEndpointID isEqualToString:[client getEndpointID]])
                            {
                                // Get the existing instance for this connection, or create a new one if necessary
                                RespokeConnection *connection = [client getConnectionWithID:newConnectionID endpointID:newEndpointID skipCreate:NO];

                                if (connection)
                                {
                                    [nameList addObject:connection];
                                }
                            }
                        }

                        // If certain connections present in the members array prior to this method are somehow no longer in the list received from the server, it's assumed a pending onLeave message will handle flushing it out of the client cache after this method completes
                        [members removeAllObjects];
                        [members addObjectsFromArray:nameList];

                        successHandler(nameList);
                    }
                    else
                    {
                        errorHandler(@"Invalid response from server");
                    }
                }
            }];
        }
        else
        {
            errorHandler(@"Group name must be specified");
        }
    }
    else
    {
        errorHandler(@"Not a member of this group anymore.");
    }
}


- (void)leaveWithSuccessHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if ([self isJoined])
    {
        if ([groupID length])
        {
            NSString *urlEndpoint = @"/v1/groups/";
            NSDictionary *data = @{ @"groups": @[groupID] };

            [signalingChannel sendRESTMessage:@"delete" url:urlEndpoint data:data responseHandler:^(id response, NSString *errorMessage) {
                if (errorMessage)
                {
                    errorHandler(errorMessage);
                }
                else
                {
                    joined = NO;
                    successHandler();
                }
            }];
        }
        else
        {
            errorHandler(@"Group name must be specified");
        }
    }
    else
    {
        errorHandler(@"Not a member of this group anymore.");
    }
}

- (void)joinWithSuccessHandler:(void (^)(void))successHandler
                  errorHandler:(void (^)(NSString *))errorHandler
{
    if (![self isConnected]) {
        errorHandler(@"Can't complete request when not connected. Please reconnect!");
        return;
    }

    if (![groupID length]) {
        errorHandler(@"Group name must be specified");
        return;
    }

    NSString* urlEndpoint = [NSString stringWithFormat:@"/v1/groups/%@", groupID];
    [signalingChannel sendRESTMessage:@"post" url:urlEndpoint data:nil
                      responseHandler:^(id response, NSString *errorMessage) {
        if (errorMessage) {
            errorHandler(errorMessage);
            return;
        }

        joined = YES;
        successHandler();
    }];
}


- (BOOL)isJoined
{
    return joined && [self isConnected];
}


- (BOOL)isConnected {
    return signalingChannel && signalingChannel.connected;
}


- (NSString*)getGroupID
{
    return groupID;
}


- (void)sendMessage:(NSString*)message push:(BOOL)push
     successHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    [self sendMessage:message push:push persist:NO
       successHandler:successHandler errorHandler:errorHandler];
}

- (void)sendMessage:(NSString *)message push:(BOOL)push persist:(BOOL)persist
     successHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString *))errorHandler
{
    if (![self isJoined]) {
        errorHandler(@"Not a member of this group anymore.");
        return;
    }

    if (![groupID length]) {
        errorHandler(@"Group name must be specified");
        return;
    }

    NSNumber *pushFlag = @(push);
    NSNumber *persistFlag = @(persist);

    NSDictionary *data = @{
        @"endpointId": [client getEndpointID],
        @"message": message,
        @"push": pushFlag,
        @"persist": persistFlag
    };

    NSString *urlEndpoint = [NSString stringWithFormat:@"/v1/groups/%@/publish/", groupID];

    [signalingChannel sendRESTMessage:@"post" url:urlEndpoint data:data
                      responseHandler:^(id response, NSString *errorMessage) {
        if (errorMessage) {
            errorHandler(errorMessage);
            return;
        }

        successHandler();
    }];
}


- (void)connectionDidJoin:(RespokeConnection*)connection
{
    [members addObject:connection];
    [self.delegate onJoin:connection sender:self];
}


- (void)connectionDidLeave:(RespokeConnection*)connection
{
    [members removeObjectIdenticalTo:connection];
    [self.delegate onLeave:connection sender:self];
}


- (void)didReceiveMessage:(NSString*)message fromEndpoint:(RespokeEndpoint*)endpoint withTimestamp:(NSDate*)timestamp
{
    [self.delegate onGroupMessage:message fromEndpoint:endpoint sender:self timestamp:timestamp];
}


@end
