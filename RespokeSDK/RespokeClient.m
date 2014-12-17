//
//  RespokeClient.m
//  Respoke SDK
//
//  Created by Jason Adams on 7/11/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "RespokeClient+private.h"
#import "APIGetToken.h"
#import "APIDoOpen.h"
#import "RespokeSignalingChannel.h"
#import "RespokeGroup+private.h"
#import "RespokeCall+private.h"
#import "RespokeEndpoint+private.h"
#import "RespokeConnection+private.h"
#import "Respoke+private.h"

#define RECONNECT_INTERVAL 0.5 ///< The exponential step interval between automatic reconnect attempts, in seconds


@interface RespokeClient () <SocketIODelegate, RespokeSignalingChannelDelegate> {
    NSString *localEndpointID;  ///< The local endpoint ID
    NSString *applicationToken;  ///< The application token to use
    RespokeSignalingChannel *signalingChannel;  ///< The signaling channel to use
    NSMutableArray *calls;  ///< An array of the active calls
    NSMutableDictionary *groups;  ///< An array of the groups this client is a member of
    NSMutableArray *knownEndpoints;  ///< An array of the known endpoints
    NSObject *presence;  ///< The current presence of this client
    NSString *applicationID;  ///< The application ID to use when connecting in development mode
    BOOL reconnect;  ///< Indicates if the client should automatically reconnect if the web socket disconnects
    NSInteger reconnectCount;  ///< A count of how many times reconnection has been attempted
    BOOL connectionInProgress;  ///< Indicates if the client is in the middle of attempting to connect
}

@end


@implementation RespokeClient


- (instancetype)init
{
    if (self = [super init])
    {
        calls = [[NSMutableArray alloc] init];
        groups = [[NSMutableDictionary alloc] init];
        knownEndpoints = [[NSMutableArray alloc] init];
    }

    return self;
}


- (void)dealloc
{
    // Inform the shared singleton that this client is going away
    [[Respoke sharedInstance] unregisterClient:self];
}


- (void)connectWithEndpointID:(NSString*)endpoint appID:(NSString*)appID reconnect:(BOOL)shouldReconnect initialPresence:(NSObject*)newPresence errorHandler:(void (^)(NSString*))errorHandler
{
    if (([endpoint length]) && ([appID length]))
    {
        connectionInProgress = YES;
        reconnect = shouldReconnect;
        applicationID = appID;
        
        APIGetToken *getToken = [[APIGetToken alloc] init];
        getToken.appID = appID;
        getToken.endpointID = endpoint;

        [getToken goWithSuccessHandler:^{
            [self connectWithTokenID:getToken.token initialPresence:newPresence errorHandler:^(NSString *errorMessage){
                connectionInProgress = NO;
                errorHandler(errorMessage);
            }];
        } errorHandler:^(NSString *errorMessage){
            connectionInProgress = NO;
            errorHandler(errorMessage);
        }];
    }
    else
    {
        errorHandler(@"AppID and endpointID must be specified");
    }
}


- (void)connectWithTokenID:(NSString*)tokenID initialPresence:(NSObject*)newPresence errorHandler:(void (^)(NSString*))errorHandler
{
    if ([tokenID length])
    {
        connectionInProgress = YES;
        APIDoOpen *doOpen = [[APIDoOpen alloc] init];
        doOpen.tokenID = tokenID;

        [doOpen goWithSuccessHandler:^{
            // Remember the presence value to set once connected
            presence = newPresence;
            
            signalingChannel = [[RespokeSignalingChannel alloc] initWithAppToken:doOpen.appToken];
            signalingChannel.delegate = self;
            [signalingChannel authenticate];
        } errorHandler:^(NSString *errorMessage){
            connectionInProgress = NO;
            errorHandler(errorMessage);
        }];
    }
    else
    {
        errorHandler(@"TokenID must be specified");
    }
}


- (void)joinGroup:(NSString*)groupName successHandler:(void (^)(RespokeGroup*))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if (signalingChannel && signalingChannel.connected)
    {
        if ([groupName length])
        {
            NSString *urlEndpoint = @"/v1/groups/";
            NSDictionary *data = @{ @"groups": @[groupName] };

            [signalingChannel sendRESTMessage:@"post" url:urlEndpoint data:data responseHandler:^(id response, NSString *errorMessage) {
                if (errorMessage)
                {
                    errorHandler(errorMessage);
                }
                else
                {
                    RespokeGroup *newGroup = [[RespokeGroup alloc] initWithGroupID:groupName appToken:applicationToken signalingChannel:signalingChannel client:self];
                    [groups setObject:newGroup forKey:groupName];

                    successHandler(newGroup);
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
        errorHandler(@"Can't complete request when not connected. Please reconnect!");
    }
}


- (void)disconnect
{
    reconnect = NO;
    [signalingChannel disconnect];
}


- (BOOL)isConnected
{
    return (signalingChannel && signalingChannel.connected);
}


- (RespokeConnection*)getConnectionWithID:(NSString*)connectionID endpointID:(NSString*)endpointID skipCreate:(BOOL)skipCreate
{
    RespokeConnection *connection = nil;

    if (connectionID)
    {
        RespokeEndpoint *endpoint = [self getEndpointWithID:endpointID skipCreate:skipCreate];

        if (endpoint)
        {
            for (RespokeConnection *eachConnection in endpoint.connections)
            {
                if ([eachConnection.connectionID isEqualToString:connectionID])
                {
                    connection = eachConnection;
                    break;
                }
            }

            if (!connection && !skipCreate)
            {
                connection = [[RespokeConnection alloc] initWithSignalingChannel:signalingChannel connectionID:connectionID endpoint:endpoint];
                [[endpoint getMutableConnections] addObject:connection];
            }
        }
    }

    return connection;
}


- (RespokeEndpoint*)getEndpointWithID:(NSString*)endpointIDToFind skipCreate:(BOOL)skipCreate
{
    RespokeEndpoint *endpoint = nil;

    if (endpointIDToFind)
    {
        for (RespokeEndpoint *eachEndpoint in knownEndpoints)
        {
            if ([eachEndpoint.endpointID isEqualToString:endpointIDToFind])
            {
                endpoint = eachEndpoint;
                break;
            }
        }

        if (!endpoint && !skipCreate)
        {
            endpoint = [[RespokeEndpoint alloc] initWithSignalingChannel:signalingChannel endpointID:endpointIDToFind];
            [knownEndpoints addObject:endpoint];

            // **** TODO: register presence
        }
    }

    return endpoint;
}


- (NSObject*)getPresence
{
    return [presence copy];
}


- (void)setPresence:(NSObject*)newPresence successHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if (signalingChannel && signalingChannel.connected)
    {
        NSObject *presenceToSet = newPresence;

        if (!presenceToSet)
        {
            presenceToSet = @"available";
        }
        
        NSDictionary *data = @{@"presence": @{@"type": presenceToSet}};
        
        [signalingChannel sendRESTMessage:@"post" url:@"/v1/presence" data:data responseHandler:^(id response, NSString *errorMessage) {
            if (errorMessage)
            {
                if (errorHandler)
                {
                    errorHandler(errorMessage);
                }
            }
            else
            {
                presence = presenceToSet;
                
                if (successHandler)
                {
                    successHandler();
                }
            }
        }];
    }
    else
    {
        if (errorHandler)
        {
            errorHandler(@"Can't complete request when not connected. Please reconnect!");
        }
    }
}


#pragma mark - Private methods


- (NSString*)getEndpointID
{
    return localEndpointID;
}


- (void)performReconnect
{
    if (applicationID)
    {
        reconnectCount++;
        [self performSelector:@selector(actuallyReconnect) withObject:nil afterDelay:RECONNECT_INTERVAL * (reconnectCount - 1)];
    }
}


- (void)actuallyReconnect
{
    if ((!signalingChannel || !signalingChannel.connected) && reconnect)
    {
        if (connectionInProgress)
        {
            // The client app must have initiated a connection manually during the timeout period. Try again later
            [self performReconnect];
        }
        else
        {
            [self connectWithEndpointID:localEndpointID appID:applicationID reconnect:reconnect initialPresence:presence errorHandler:^(NSString *errorMessage){
                // A REST API call failed. Socket errors are handled in the onError callback
                [self.delegate onError:[NSError errorWithDomain:@"respoke" code:100 userInfo:@{NSLocalizedDescriptionKey: errorMessage}] fromClient:self];

                // Try again later
                [self performReconnect];
            }];
        }
    }
}


#pragma mark - RespokeSignalingChannelDelegate


- (void)onConnect:(RespokeSignalingChannel*)sender endpointID:(NSString*)endpointID
{
    connectionInProgress = NO;
    reconnectCount = 0;
    localEndpointID = endpointID;

    [[Respoke sharedInstance] client:self connectedWithEndpoint:endpointID];
    
    // Try to set the presence to the initial or last set state
    [self setPresence:presence successHandler:nil errorHandler:nil];
    
    [self.delegate onConnect:self];
}


- (void)onDisconnect:(RespokeSignalingChannel*)sender
{
    // Can only reconnect in development mode, not brokered mode
    BOOL willReconnect = reconnect && (applicationID != nil);

    [calls removeAllObjects];
    [groups removeAllObjects];
    [knownEndpoints removeAllObjects];
    [self.delegate onDisconnect:self reconnecting:willReconnect];
    signalingChannel = nil;

    if (willReconnect)
    {
        [self performReconnect];
    }
}


- (void)onIncomingCallWithSDP:(NSDictionary*)sdp sessionID:(NSString*)sessionID connectionID:(NSString*)connectionID endpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender
{
    RespokeEndpoint *endpoint = [self getEndpointWithID:endpointID skipCreate:NO];

    if (endpoint)
    { 
        // A remote device is trying to call us, so create a call instance to deal with it
        RespokeCall *call = [[RespokeCall alloc] initWithSignalingChannel:signalingChannel incomingCallSDP:sdp sessionID:sessionID connectionID:connectionID endpoint:endpoint directConnectionOnly:NO];
        
        [self.delegate onCall:call sender:self];
    }
    else
    {
        NSLog(@"------Error: Could not create Endpoint for incoming call");
    }
}



- (void)onIncomingDirectConnectionWithSDP:(NSDictionary*)sdp sessionID:(NSString*)sessionID connectionID:(NSString*)connectionID endpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender
{
    RespokeEndpoint *endpoint = [self getEndpointWithID:endpointID skipCreate:NO];
    
    if (endpoint)
    {
        // A remote device is trying to create a direct connection with us, so create a call instance to deal with it
        [[RespokeCall alloc] initWithSignalingChannel:signalingChannel incomingCallSDP:sdp sessionID:sessionID connectionID:connectionID endpoint:endpoint directConnectionOnly:YES];
    }
    else
    {
        NSLog(@"------Error: Could not create Endpoint for incoming direct connection");
    }
}


- (void)onError:(NSError *)error sender:(RespokeSignalingChannel*)sender
{
    [self.delegate onError:error fromClient:self];

    if (signalingChannel && !signalingChannel.connected)
    {
        connectionInProgress = NO;

        if (reconnect)
        {
            [self performReconnect];
        }
    }
}


- (void)onJoinGroupID:(NSString*)groupID endpointID:(NSString*)endpointID connectionID:(NSString*)connectionID sender:(RespokeSignalingChannel*)sender
{
    // only pass on notifications about people other than ourselves
    if ((endpointID) && (![endpointID isEqualToString:localEndpointID]))
    {
        RespokeGroup *group = [groups objectForKey:groupID];

        if (group)
        {
            // Get the existing instance for this connection, or create a new one if necessary
            RespokeConnection *connection = [self getConnectionWithID:connectionID endpointID:endpointID skipCreate:NO];

            if (connection)
            {
                [group connectionDidJoin:connection];
            }
        }
    }
}


- (void)onLeaveGroupID:(NSString*)groupID endpointID:(NSString*)endpointID connectionID:(NSString*)connectionID sender:(RespokeSignalingChannel*)sender
{
    // only pass on notifications about people other than ourselves
    if ((endpointID) && (![endpointID isEqualToString:localEndpointID]))
    {
        RespokeGroup *group = [groups objectForKey:groupID];

        if (group)
        {
            // Get the existing instance for this connection. If we are not already aware of it, ignore it
            RespokeConnection *connection = [self getConnectionWithID:connectionID endpointID:endpointID skipCreate:YES];

            if (connection)
            {
                [group connectionDidLeave:connection];
            }
        }
    }   
}


- (void)onMessage:(NSString*)message fromEndpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender
{
    RespokeEndpoint *endpoint = [self getEndpointWithID:endpointID skipCreate:YES];

    if (endpoint)
    {
        [endpoint didReceiveMessage:message];
    }
}


- (void)onGroupMessage:(NSString*)message groupID:(NSString*)groupID endpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender
{
    RespokeGroup *group = [groups objectForKey:groupID];

    if (group)
    {
        RespokeEndpoint *endpoint = [self getEndpointWithID:endpointID skipCreate:NO];

        [group didReceiveMessage:message fromEndpoint:endpoint];
    }
}


- (void)onPresence:(NSObject*)newPresence connectionID:(NSString*)connectionID endpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender
{
    // Get the existing instance for this connection. If we are not already aware of it, ignore it
    RespokeConnection *connection = [self getConnectionWithID:connectionID endpointID:endpointID skipCreate:NO];

    if (connection)
    {
        [connection setPresence:newPresence];

        RespokeEndpoint *endpoint = [connection getEndpoint];
        [endpoint resolvePresence];
    }   
}


- (void)callCreated:(RespokeCall*)call
{
    [calls addObject:call];
}


- (void)callTerminated:(RespokeCall*)call
{
    [calls removeObject:call];
}


- (RespokeCall*)callWithID:(NSString*)sessionID
{
    RespokeCall *call = nil;
    
    for (RespokeCall *eachCall in calls)
    {
        if ([[eachCall getSessionID] isEqualToString:sessionID])
        {
            call = eachCall;
            break;
        }
    }
    
    return call;
}


- (void)directConnectionAvailable:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint
{
    [self.delegate onIncomingDirectConnection:directConnection endpoint:endpoint];
}


@end
