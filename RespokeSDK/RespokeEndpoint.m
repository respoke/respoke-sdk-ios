//
//  RespokeEndpoint.m
//  Respoke SDK
//
//  Created by Jason Adams on 7/14/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "RespokeEndpoint+private.h"
#import "RespokeCall+private.h"
#import "RespokeConnection+private.h"


@interface RespokeEndpoint () {
    RespokeSignalingChannel *signalingChannel;  ///< The signaling channel to use
    RespokeClient __weak *client;  ///< The client to which this endpoint belongs
    NSString *endpointID;  ///< The ID of this endpoint
    NSMutableArray *connections;  ///< The connections associated with this endpoint
    NSObject *presence;  ///< The current presence of this endpoint
    RespokeDirectConnection __weak *directConnection;  ///< The direct connection established with this endpoint
}

@end


@implementation RespokeEndpoint

@synthesize endpointID;
@synthesize connections;
@synthesize directConnection;


- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel endpointID:(NSString*)newEndpointID client:(RespokeClient*)newClient
{
    if (self = [super init])
    {
        endpointID = newEndpointID;
        connections = [[NSMutableArray alloc] init];
        signalingChannel = channel;
        client = newClient;
    }

    return self;
}


- (void)sendMessage:(NSString*)message successHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if (signalingChannel && signalingChannel.connected)
    {
        NSDictionary *data = @{@"to": self.endpointID, @"message": message};

        [signalingChannel sendRESTMessage:@"post" url:@"/v1/messages" data:data responseHandler:^(id response, NSString *errorMessage) {
            if (errorMessage)
            {
                errorHandler(errorMessage);
            }
            else
            {
                successHandler();
            }
        }];
    }
    else
    {
        errorHandler(@"Can't complete request when not connected. Please reconnect!");
    }
}


- (RespokeCall*)startVideoCallWithDelegate:(id <RespokeCallDelegate>)delegate remoteVideoView:(UIView*)newRemoteView localVideoView:(UIView*)newLocalView
{
    RespokeCall *call = nil;

    if (signalingChannel && signalingChannel.connected)
    {
        call = [[RespokeCall alloc] initWithSignalingChannel:signalingChannel endpoint:self audioOnly:NO directConnectionOnly:NO];
        call.delegate = delegate;
        call.remoteView = newRemoteView;
        call.localView = newLocalView;

        [call startCall];
    }

    return call;
}


- (RespokeCall*)startAudioCallWithDelegate:(id <RespokeCallDelegate>)delegate
{
    RespokeCall *call = nil;

    if (signalingChannel && signalingChannel.connected)
    {
        call = [[RespokeCall alloc] initWithSignalingChannel:signalingChannel endpoint:self audioOnly:YES directConnectionOnly:NO];
        call.delegate = delegate;

        [call startCall];
    }

    return call;
}


- (NSString*)getEndpointID
{
    return endpointID;
}


- (NSArray*)getConnections
{
    return [connections copy];
}


- (RespokeConnection*)getConnectionWithID:(NSString*)connectionID skipCreate:(BOOL)skipCreate
{
    RespokeConnection *connection = nil;

    for (RespokeConnection *eachConnection in connections)
    {
        if ([eachConnection.connectionID isEqualToString:connectionID])
        {
            connection = eachConnection;
            break;
        }
    }

    if (!connection && !skipCreate)
    {
        connection = [[RespokeConnection alloc] initWithSignalingChannel:signalingChannel connectionID:connectionID endpoint:self];
        [connections addObject:connection];
    }

    return connection;
}


- (NSMutableArray*)getMutableConnections
{
    return connections;
}


- (void)didReceiveMessage:(NSString*)message withTimestamp:(NSDate*)timestamp
{
    [self.delegate onMessage:message sender:self timestamp:timestamp];
}


- (void)registerPresenceWithSuccessHandler:(void (^)())successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if (signalingChannel && signalingChannel.connected)
    {
        [signalingChannel registerPresence:@[self.endpointID] successHandler:^(NSArray *initialPresenceArray){
            
            if (initialPresenceArray && [initialPresenceArray isKindOfClass:[NSArray class]])
            {
                for (NSDictionary *eachEndpointData in initialPresenceArray)
                {
                    NSString *dataEndpointID = [eachEndpointData objectForKey:@"endpointId"];
                    
                    // Ignore presence data related to other endpoints
                    if ([dataEndpointID isEqualToString:endpointID])
                    {
                        NSDictionary *connectionData = [eachEndpointData objectForKey:@"connectionStates"];
                        
                        if (connectionData && [connectionData isKindOfClass:[NSDictionary class]])
                        {
                            NSArray *connectionIDs = [connectionData allKeys];
                            for (NSString *eachConnectionID in connectionIDs)
                            {
                                NSDictionary *presenceDict = [connectionData objectForKey:eachConnectionID];
                                
                                if (presenceDict && [presenceDict isKindOfClass:[NSDictionary class]])
                                {
                                    NSObject *newPresence = [presenceDict objectForKey:@"type"];
                                    RespokeConnection *connection = [self getConnectionWithID:eachConnectionID skipCreate:NO];
                                    
                                    if (connection && newPresence)
                                    {
                                        [connection setPresence:newPresence];
                                    }
                                }
                            }
                        }
                    }
                }
                
                [self resolvePresence];
            }
            
            if (successHandler)
            {
                successHandler();
            }
        } errorHandler:^(NSString *errorMessage){
            if (errorHandler)
            {
                errorHandler(errorMessage);
            }
        }];
    }
    else
    {
        errorHandler(@"Can't complete request when not connected. Please reconnect!");
    }
}


- (NSObject*)getPresence
{
    return [presence copy];
}


- (void)setPresence:(NSObject*)newPresence
{
    presence = newPresence;
}


- (void)resolvePresence
{
    NSMutableArray *list = [[NSMutableArray alloc] init];

    for (RespokeConnection *eachConnection in connections)
    {
        NSObject *connectionPresence = [eachConnection getPresence];

        if (connectionPresence)
        {
            [list addObject:connectionPresence];
        }
    }

    if (client.resolveDelegate)
    {
        presence = [client.resolveDelegate resolvePresence:list];
    }
    else
    {
        NSArray *options = @[@"chat", @"available", @"away", @"dnd", @"xa", @"unavailable"];
        NSString *newPresence = nil;

        for (NSString *eachOption in options)
        {
            for (NSObject *eachObject in list)
            {
                if ([eachObject isKindOfClass:[NSString class]])
                {
                    if ([[((NSString*)eachObject) lowercaseString] isEqualToString:eachOption])
                    {
                        newPresence = eachOption;
                        break;
                    }
                }
            }

            if (newPresence)
            {
                break;
            }
        }

        if (!newPresence)
        {
            newPresence = @"available";
        }

        presence = newPresence;
    }

    [self.delegate onPresence:presence sender:self];   
}


- (RespokeDirectConnection*)directConnection
{
    return directConnection;
}


- (void)setDirectConnection:(RespokeDirectConnection*)newDirectConnection
{
    directConnection = newDirectConnection;
}


- (RespokeDirectConnection*)startDirectConnection
{
    // The init method will call the setDirectConnection method on this endpoint instance with a reference to the new RespokeDirectConnection object
    RespokeCall *call = [[RespokeCall alloc] initWithSignalingChannel:signalingChannel endpoint:self audioOnly:NO directConnectionOnly:YES];
    [call startCall];

    return directConnection;
}


@end
