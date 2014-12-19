//
//  RespokeSignalingChannel.m
//  Respoke SDK
//
//  Created by Jason Adams on 7/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "RespokeSignalingChannel.h"
#import "RespokeCall+private.h"
#import "RespokeEndpoint+private.h"


#define RESPOKE_SOCKETIO_PORT 443


@implementation RespokeSignalingChannel


- (instancetype)initWithAppToken:(NSString*)token
{
    if (self = [super init])
    {
        appToken = token;
    }

    return self;
}


- (void)authenticate
{
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    socketIO.useSecure = YES;
    [socketIO connectToHost:[NSString stringWithFormat:@"%@", RESPOKE_BASE_URL] onPort:RESPOKE_SOCKETIO_PORT withParams:[NSDictionary dictionaryWithObjectsAndKeys:appToken, @"app-token", nil]];
}


- (void)sendRESTMessage:(NSString *)httpMethod url:(NSString *)url data:(NSDictionary*)data responseHandler:(void (^)(id, NSString*))responseHandler
{
    if (self.connected)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@{@"App-Token": appToken} forKey:@"headers"];
        [dict setObject:url forKey:@"url"];

        if (data)
        {
            [dict setObject:data forKey:@"data"];
        }
        
        [socketIO sendEvent:httpMethod withData:dict andAcknowledge:^(id argsData) {
            id response = argsData;
            NSString *errorString = nil;

            if (argsData && [argsData isKindOfClass:[NSString class]])
            {
                if ([argsData isEqualToString:@"null"])
                {
                    response = nil;
                }
                else
                {
                    NSError *error;
                    id jsonResult = [NSJSONSerialization JSONObjectWithData:[argsData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
                    if (!error)
                    {
                        response = jsonResult;

                        if ([jsonResult isKindOfClass:[NSDictionary class]])
                        {
                            errorString = [jsonResult objectForKey:@"error"];
                        }
                    }
                    else
                    {
                        errorString = @"Unexpected response received";
                    }
                }
            }
            else if (!argsData)
            {
                errorString = @"Unexpected response received";
            }

            responseHandler(response, errorString);
        }];
    }
    else
    {
        responseHandler(nil, @"Not connected");
    }
}


- (void)sendSignalMessage:(NSObject*)message toEndpointID:(NSString*)toEndpointID successHandler:(void (^)())successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&jsonError];
    
    if (!jsonError)
    {
        NSString *jsonSignal = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSDictionary *data = @{@"signal": jsonSignal, @"to": toEndpointID, @"toType": @"web"};

        [self sendRESTMessage:@"post" url:@"/v1/signaling" data:data responseHandler:^(id response, NSString *errorMessage) {
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
        errorHandler(@"Error encoding signal to json");
    }
}


- (void)disconnect
{
    [socketIO disconnect];
}


- (void)registerPresence:(NSArray*)endpointList successHandler:(void (^)(NSArray*))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if (self.connected)
    {
        NSDictionary *data = @{@"endpointList": endpointList};

        [self sendRESTMessage:@"post" url:@"/v1/presenceobservers" data:data responseHandler:^(id response, NSString *errorMessage) {
            if (errorMessage)
            {
                errorHandler(errorMessage);
            }
            else
            {
                successHandler(response);
            }
        }];
    }
    else
    {
        errorHandler(@"Can't complete request when not connected. Please reconnect!");
    }
}


#pragma mark - SocketIODelegate


- (void)socketIODidConnect:(SocketIO *)socket
{
    self.connected = YES;

    [self sendRESTMessage:@"post" url:@"/v1/connections" data:nil responseHandler:^(id response, NSString *errorMessage) {
        if (errorMessage)
        {
            [self.delegate onError:[NSError errorWithDomain:NSURLErrorDomain code:5 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected response received"}] sender:self];
        }
        else
        {
            if (response && ([response isKindOfClass:[NSDictionary class]]))
            {   
                connectionID = [response objectForKey:@"id"];
                NSString *endpointID = [response objectForKey:@"endpointId"];
                [self.delegate onConnect:self endpointID:endpointID];
            }
            else
            {
                [self.delegate onError:[NSError errorWithDomain:NSURLErrorDomain code:5 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected response received"}] sender:self];
            }
        }
    }];
}


- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"socketIODidDisconnect: %@", [error localizedDescription]);
    self.connected = NO;
    socketIO = nil;
    [self.delegate onDisconnect:self];
}


- (void)socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet
{
    NSLog(@"didReceiveMessage >>> data: %@", packet.data);

}


- (void)socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet
{
    NSLog(@"didReceiveJSON");

}


- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSError *error;
    id jsonResult = [NSJSONSerialization JSONObjectWithData:[packet.data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (!error)
    {
        if (jsonResult && ([jsonResult isKindOfClass:[NSDictionary class]]))
        {
            NSDictionary *dict = (NSDictionary*)jsonResult;

            NSString *name = [dict objectForKey:@"name"];
            NSArray *args = [dict objectForKey:@"args"];

            if ([name isEqualToString:@"join"])
            {
                for (NSDictionary *eachInstance in args)
                {
                    NSString *endpoint = [eachInstance objectForKey:@"endpointId"];
                    NSString *connection = [eachInstance objectForKey:@"connectionId"];
                    NSDictionary *headerDict = [eachInstance objectForKey:@"header"];
                    NSString *groupID = [headerDict objectForKey:@"channel"];
                    
                    [self.delegate onJoinGroupID:groupID endpointID:endpoint connectionID:connection sender:self];
                }
            }
            else if ([name isEqualToString:@"leave"])
            {
                for (NSDictionary *eachInstance in args)
                {
                    NSString *endpoint = [eachInstance objectForKey:@"endpointId"];
                    NSString *connection = [eachInstance objectForKey:@"connectionId"];
                    NSDictionary *headerDict = [eachInstance objectForKey:@"header"];
                    NSString *groupID = [headerDict objectForKey:@"channel"];

                    [self.delegate onLeaveGroupID:groupID endpointID:endpoint connectionID:connection sender:self];
                }
            }
            else if ([name isEqualToString:@"message"])
            {
                for (NSDictionary *eachInstance in args)
                {
                    NSDictionary *header = [eachInstance objectForKey:@"header"];
                    NSString *endpoint = [header objectForKey:@"from"];
                    NSString *message = [eachInstance objectForKey:@"body"];
                    NSNumber *timestampNumber = [header objectForKey:@"timestamp"];
                    NSDate *timestamp = nil;
                    if (timestampNumber)
                    {
                        NSTimeInterval timestampInterval = (NSTimeInterval) ([timestampNumber longLongValue] / 1000);
                        timestamp = [NSDate dateWithTimeIntervalSince1970:timestampInterval];
                    }
                    else
                    {
                        timestamp = [NSDate date];
                    }
                    [self.delegate onMessage:message fromEndpointID:endpoint sender:self timestamp:timestamp];
                }
            }
            else if ([name isEqualToString:@"signal"])
            {
                for (NSDictionary *eachInstance in args)
                {
                    [self routeSignal:eachInstance];
                }
            }
            else if ([name isEqualToString:@"pubsub"])
            {
                for (NSDictionary *eachInstance in args)
                {
                    NSString *message = [eachInstance objectForKey:@"message"];
                    NSDictionary *headerDict = [eachInstance objectForKey:@"header"];
                    NSString *groupID = [headerDict objectForKey:@"channel"];
                    NSString *endpoint = [headerDict objectForKey:@"from"];
                    
                    [self.delegate onGroupMessage:message groupID:groupID endpointID:endpoint sender:self];
                }
            }
            else if ([name isEqualToString:@"presence"])
            {
                for (NSDictionary *eachInstance in args)
                {
                    NSObject *type = [eachInstance objectForKey:@"type"];
                    NSDictionary *headerDict = [eachInstance objectForKey:@"header"];
                    NSString *connection = [headerDict objectForKey:@"fromConnection"];
                    NSString *endpoint = [headerDict objectForKey:@"from"];
                    
                    [self.delegate onPresence:type connectionID:connection endpointID:endpoint sender:self];
                }
            }
        }
    }
}


- (void)socketIO:(SocketIO *)socket onError:(NSError *)error
{
    NSLog(@"------%@: socketIO error: %@", [self class], [error localizedDescription]);
    [self.delegate onError:error sender:self];
}


#pragma mark - misc


- (void)routeSignal:(NSDictionary*)message
{
    NSDictionary *signal = [message objectForKey:@"body"];
    NSDictionary *header = [message objectForKey:@"header"];
    NSString *from = [header objectForKey:@"from"];
    NSString *fromConnection = [header objectForKey:@"fromConnection"];

    if (signal && from)
    {
        NSString *signalType = [signal objectForKey:@"signalType"];
        NSString *sessionID = [signal objectForKey:@"sessionId"];
        NSString *target = [signal objectForKey:@"target"];
        NSString *toConnection = [signal objectForKey:@"connectionId"];

        if (sessionID && signalType)
        {
            BOOL isDirectConnection = [target isEqualToString:@"directConnection"];
            RespokeCall *call = [self.delegate callWithID:sessionID];

            if (([target isEqualToString:@"call"]) || (isDirectConnection))
            {
                if (call)
                {
                    if ([signalType isEqualToString:@"bye"])
                    {
                        [call hangupReceived];
                    }
                    else if ([signalType isEqualToString:@"answer"])
                    {
                        NSDictionary *sdp = [signal objectForKey:@"sessionDescription"];

                        [call answerReceived:sdp fromConnection:fromConnection];
                    }
                    else if ([signalType isEqualToString:@"connected"])
                    {
                        if ([toConnection isEqualToString:connectionID])
                        {
                            [call connectedReceived];
                        }
                        else
                        {
                            NSLog(@"Another device answered, hanging up.");
                            [call hangupReceived];
                        }
                    }
                    else if ([signalType isEqualToString:@"iceCandidates"])
                    {
                        NSArray *candidates = [signal objectForKey:@"iceCandidates"];
                        [call iceCandidatesReceived:candidates];
                    }
                }
                else if ([signalType isEqualToString:@"offer"])
                {
                    NSDictionary *sdp = [signal objectForKey:@"sessionDescription"];
                    
                    if (sdp)
                    {
                        NSNumber *timestampNumber = [header objectForKey:@"timestamp"];
                        NSDate *timestamp = nil;
                        if (timestampNumber)
                        {
                            NSTimeInterval timestampInterval = (NSTimeInterval) ([timestampNumber longLongValue] / 1000);
                            timestamp = [NSDate dateWithTimeIntervalSince1970:timestampInterval];
                        }
                        else
                        {
                            timestamp = [NSDate date];
                        }

                        if (isDirectConnection)
                        {
                            [self.delegate onIncomingDirectConnectionWithSDP:sdp sessionID:sessionID connectionID:fromConnection endpointID:from sender:self timestamp:timestamp];
                        }
                        else
                        {
                            [self.delegate onIncomingCallWithSDP:sdp sessionID:sessionID connectionID:fromConnection endpointID:from sender:self timestamp:timestamp];
                        }
                    }
                    else
                    {
                        NSLog(@"------Error: Offer missing sdp");
                    }
                }
            }
        }
        else
        {
            NSLog(@"------Error: signal is missing type or session ID. Ignoring.");
        }
    }
    else
    {
        NSLog(@"------Error: signal missing header data");
    }
}


@end
