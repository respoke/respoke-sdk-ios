//
//  RespokeSignalingChannel.h
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

#import <Foundation/Foundation.h>
#import "SocketIO.h"
#import "SocketIOPacket.h"
#import "APITransaction.h"


@protocol RespokeSignalingChannelDelegate;


/**
 *  The purpose of this class is to make a method call for each API call
 *  to the backend REST interface.  This class takes care of App authentication, websocket connection,
 *  Endpoint authentication, and all App interactions thereafter.
 */
@interface RespokeSignalingChannel : NSObject <SocketIODelegate> {
    NSString *appToken;  ///< The application token to use
    SocketIO *socketIO;  ///< The socket.io socket in use
    NSString *connectionID;  ///< The ID of this connection
    NSString *baseURL;  ///< The base URL of the Respoke service
    BOOL useHTTPS;  ///< Indicates that HTTPS should be used when connecting
}


/**
 *  The delegate that should receive notifications from the RespokeSignalingChannelDelegate protocol
 */
@property (weak) id <RespokeSignalingChannelDelegate> delegate;


/**
 *  Indicates if the signaling channel is currently connected to the cloud infrastructure
 */
@property BOOL connected;


/**
 *  Initialize a new signaling channel instance
 *
 *  @param token           The application token to use
 *  @param baseURL         The base URL of the Respoke service
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithAppToken:(NSString*)token baseURL:(NSString*)baseURL;


/**
 *  Begin the authentication process
 */
- (void)authenticate;


/**
 *  Send a REST message through the websocket
 *
 *  @param httpMethod      HTTP method to use
 *  @param url             Destination URL
 *  @param data            Data to transmit
 *  @param responseHandler Response handler to call upon completion
 */
- (void)sendRESTMessage:(NSString *)httpMethod url:(NSString *)url data:(NSDictionary*)data responseHandler:(void (^)(id, NSString*))responseHandler;


/**
 *  Send a signaling message through the websocket
 *
 *  @param message        Message to send
 *  @param toEndpointID   Destination endpoint ID
 *  @param successHandler A block to call upon successful transmission
 *  @param errorHandler   A block to call upon an error, passing the error message
 */
- (void)sendSignalMessage:(NSObject*)message toEndpointID:(NSString*)toEndpointID successHandler:(void (^)())successHandler errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  Disconnect the signaling channel from the cloud infrastructure
 */
- (void)disconnect;


/**
 *  Register to receive presence notifications for the specified list of endpoints
 *
 *  @param endpointList   An array of endpoints to register presence with
 *  @param successHandler A block to call upon successful transmission, passing an array of initial presence information for those endpoints
 *  @param errorHandler   A block to call upon an error, passing the error message
 */
- (void)registerPresence:(NSArray*)endpointList successHandler:(void (^)(NSArray*))successHandler errorHandler:(void (^)(NSString*))errorHandler;


@end


@class RespokeCall;
@class RespokeEndpoint;
@class RespokeConnection;
@class RespokeDirectConnection;


/**
 *  A delegate protocol to notify the receiver of events occurring with the connection status of the signaling channel
 */
@protocol RespokeSignalingChannelDelegate <NSObject>


/**
 *  Receive a notification from the signaling channel that it has connected to the cloud infrastructure
 *
 *  @param sender        The signaling channel that triggered the event
 *  @param endpointID    The endpointID for this connection, as reported by the server
 *  @param connectionID  The connectionID for this connection, as reported by the server
 */
- (void)onConnect:(RespokeSignalingChannel*)sender endpointID:(NSString*)endpointID connectionID:(NSString*)connectionID;


/**
 *  Receive a notification from the signaling channel that it has disconnected to the cloud infrastructure
 *
 *  @param sender The signaling channel that triggered the event
 */
- (void)onDisconnect:(RespokeSignalingChannel*)sender;


/**
 *  Receive a notification from the signaling channel that a remote endpoint is attempting to start a call
 *
 *  @param sdp           The SDP data for the call
 *  @param sessionID     The session ID of the call
 *  @param connectionID  The connectionID that is calling
 *  @param endpointID    The endpointID that is calling
 *  @param sender        The signaling channel that triggered the event
 *  @param timestamp     The call timestamp
 */
- (void)onIncomingCallWithSDP:(NSDictionary*)sdp sessionID:(NSString*)sessionID connectionID:(NSString*)connectionID endpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender timestamp:(NSDate*)timestamp;


/**
 *  Receive a notification from the signaling channel that a remote endpoint is attempting to start a direct connection
 *
 *  @param sdp           The SDP data for the directConnection
 *  @param sessionID     The session ID of the directConnection
 *  @param connectionID  The connectionID that is calling
 *  @param endpointID    The endpointID that is calling
 *  @param sender        The signaling channel that triggered the event
 *  @param timestamp     The call timestamp
 */
- (void)onIncomingDirectConnectionWithSDP:(NSDictionary*)sdp sessionID:(NSString*)sessionID connectionID:(NSString*)connectionID endpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender timestamp:(NSDate*)timestamp;

/**
 *  Receive a notification from the signaling channel that an error has occurred
 *
 *  @param error  Error message
 *  @param sender The signaling channel that triggered the event
 */
- (void)onError:(NSError *)error sender:(RespokeSignalingChannel*)sender;

/**
 *  Receive a notification from the signaling channel that an endpoint has joined this group.
 *
 *  @param groupID      The ID of the group triggering the join message
 *  @param endpointID   The ID of the endpoint that to which the connection belongs
 *  @param connectionID The ID of the connection that has joined the group
 *  @param sender       The signaling channel that triggered the event
 */
- (void)onJoinGroupID:(NSString*)groupID endpointID:(NSString*)endpointID connectionID:(NSString*)connectionID sender:(RespokeSignalingChannel*)sender;

/**
 *  Receive a notification from the signaling channel that an endpoint has left this group.
 *
 *  @param groupID      The ID of the group triggering the leave message
 *  @param endpointID   The ID of the endpoint that to which the connection belongs
 *  @param connectionID The ID of the connection that has left the group
 *  @param sender       The signaling channel that triggered the event
 */
- (void)onLeaveGroupID:(NSString*)groupID endpointID:(NSString*)endpointID connectionID:(NSString*)connectionID sender:(RespokeSignalingChannel*)sender;


/**
 *  Receive a notification from the signaling channel that a message has been sent to this group
 *
 *  @param message    The body of the message
 *  @param endpointID The ID of the endpoint sending the message
 *  @param sender     The signaling channel that triggered the event
 *  @param timestamp  The message timestamp
 */
- (void)onMessage:(NSString*)message fromEndpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender timestamp:(NSDate *)timestamp;


/**
 *  Receive a notification that a group message was received
 *
 *  @param message    The body of the message
 *  @param groupID    The ID of the group to which the message was sent
 *  @param endpointID The ID of the endpoint that sent the message
 *  @param sender     The signaling channel that triggered the event
 *  @param timestamp  The message timestamp
 */
- (void)onGroupMessage:(NSString*)message groupID:(NSString*)groupID endpointID:(NSString*)endpointID sender:(RespokeSignalingChannel*)sender timestamp:(NSDate*)timestamp;


/**
 *  Receive a notification that a presence change message was received
 *
 *  @param presence     The new presence value
 *  @param connectionID The connection ID whose presence changed
 *  @param endpoint     The endpoint ID to which the connection belongs
 *  @param sender       The signaling channel that triggered the event
 */
- (void)onPresence:(NSObject*)presence connectionID:(NSString*)connectionID endpointID:(NSString*)endpoint sender:(RespokeSignalingChannel*)sender;


/**
 *  Receive a notification from the signaling channel that a call has been created
 *
 *  @param call The RespokeCall instance that was created
 */
- (void)callCreated:(RespokeCall*)call;


/**
 *  Receive a notification from the signaling channel that a call has terminated
 *
 *  @param call The RespokeCall instance that was terminated
 */
- (void)callTerminated:(RespokeCall*)call;


/**
 *  Find a call with the specified session ID
 *
 *  @param sessionID SessionID to find
 *
 *  @return The RespokeCall instance with that sessionID. If not found, will return nil.
 */
- (RespokeCall*)callWithID:(NSString*)sessionID;


/**
 *  This event is fired when the logged-in endpoint is receiving a request to open a direct connection
 *  to another endpoint.  If the user wishes to allow the direct connection, calling 'accept' on the
 *  direct connection will allow the connection to be set up.
 */
- (void)directConnectionAvailable:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint;


@end
