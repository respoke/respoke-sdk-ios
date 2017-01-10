//
//  RespokeClient.h
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
#import <UIKit/UIKit.h>


@class RespokeGroup;
@class RespokeCall;
@class RespokeConnection;
@class RespokeEndpoint;
@class RespokeDirectConnection;
@protocol RespokeClientDelegate;
@protocol RespokeResolvePresenceDelegate;
@protocol RespokeCallDelegate;


/**
 *  This is a top-level interface to the API. It handles authenticating the app to the
 *  API server, receiving server-side app-specific information, keeping track of connection status and presence,
 *  accepting callbacks and listeners, and interacting with information the library keeps
 *  track of, like groups and endpoints. The client also keeps track of default settings for calls and direct
 *  connections as well as automatically reconnecting to the service when network activity is lost.
 */
@interface RespokeClient : NSObject


/**
 *  The delegate that should receive notifications from the RespokeClientDelegate protocol
 */
@property (weak) id <RespokeClientDelegate> delegate;


/**
 *  The optional delegate that should resolve the presence for an endpoint
 */
@property (weak) id <RespokeResolvePresenceDelegate> resolveDelegate;


/**
 *  Connect to the Respoke infrastructure and authenticate in development mode using the specified endpoint ID and app ID.
 *  Attempt to obtain an authentication token automatically from the Respoke infrastructure. Get the first set of TURN
 *  credentials and store them internally for later use.
 *
 *  @param endpoint       The endpoint ID to use when connecting
 *  @param appID          Your Application ID
 *  @param reconnect      Whether or not to automatically reconnect to the Respoke service when a disconnect occurs.
 *  @param presence       The optional initial presence value to set for this client
 *  @param errorHandler   A block called when an error occurs, passing a string describing the error
 */
- (void)connectWithEndpointID:(NSString*)endpoint appID:(NSString*)appID reconnect:(BOOL)reconnect initialPresence:(NSObject*)presence errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  Connect to the Respoke infrastructure and authenticate with the specified token ID. Get the first set of TURN
 *  credentials and store them internally for later use.
 *
 *  @param tokenID      The token ID to use when connecting
 *  @param presence     The optional initial presence value to set for this client
 *  @param errorHandler A block called when an error occurs, passing a string describing the error
 */
- (void)connectWithTokenID:(NSString*)tokenID initialPresence:(NSObject*)presence errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  Create a new call with audio and video.
 *
 *  @param delegate      The delegate to receive notifications about the new call
 *  @param endpointID    The ID of the endpoint to call
 *  @param newRemoteView A UIView on which to project the remote video
 *  @param newLocalView  A UIView on which to project the local video
 *
 *  @return A reference to the new RespokeCall object representing this call
 */
- (RespokeCall*)startVideoCallWithDelegate:(id <RespokeCallDelegate>)delegate endpointID:(NSString*)endpointID remoteVideoView:(UIView*)newRemoteView localVideoView:(UIView*)newLocalView;


/**
 *  Create a new audio-only call.
 *
 *  @param delegate     The delegate to receive notifications about the new call
 *  @param endpointID   The ID of the endpoint to call
 *
 *  @return A reference to the new RespokeCall object representing this call
 */
- (RespokeCall*)startAudioCallWithDelegate:(id <RespokeCallDelegate>)delegate endpointID:(NSString*)endpointID;

/**
 *  Initiate a call to a conference.
 *
 *  @param delegate     The delegate to receive notifications about the new call
 *  @param conferenceID The ID of the conference to call
 *
 *  @return A reference to the new RespokeCall object representing this call
 */
- (RespokeCall*)joinConferenceWithDelegate:(id <RespokeCallDelegate>)delegate conferenceID:(NSString*)conferenceID;

/**
 *  Join a list of Groups and begin keeping track of them.
 *
 *  @param groupNames      The names of the groups to join
 *  @param errorHandler    A block called when an error occurs, passing a string describing the error
 *  @param successHandler  A block called when the group is joined successfully, passing a reference to the group
 */
- (void)joinGroups:(NSArray*)groupNames successHandler:(void (^)(NSArray*))successHandler errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  Disconnect from the Respoke infrastructure, leave all groups, invalidate the token, and disconnect the websocket.
 */
- (void)disconnect;


/**
 *  Check whether we are connected to the backend infrastructure.
 *
 *  @return True if connected
 */
- (BOOL)isConnected;


/**
 *  Find a Connection by id and return it. In most cases, if we don't find it we will create it. This is useful
 *  in the case of dynamic endpoints where groups are not in use. Set skipCreate=true to return nil
 *  if the Connection is not already known.
 *
 *  @param connectionID The ID of the connection to return
 *  @param endpointID   The ID of the endpoint to which this connection belongs
 *  @param skipCreate   If true, reurn nil if the connection is not already known
 *
 *  @return The connection whose ID was specified
 */
- (RespokeConnection*)getConnectionWithID:(NSString*)connectionID endpointID:(NSString*)endpointID skipCreate:(BOOL)skipCreate;


/**
 *  Find an endpoint by id and return it. In most cases, if we don't find it we will create it. This is useful
 *  in the case of dynamic endpoints where groups are not in use. Set skipCreate=true to return nil
 *  if the Endpoint is not already known.
 *
 *  @param endpointIDToFind The ID of the endpoint to return
 *  @param skipCreate       If true, reurn nil if the connection is not already known
 *
 *  @return The endpoint whose ID was specified
 */
- (RespokeEndpoint*)getEndpointWithID:(NSString*)endpointIDToFind skipCreate:(BOOL)skipCreate;


/**
 *  Get the current presence of this client
 *
 *  @return The current presence value
 */
- (NSObject*)getPresence;


/**
 *  Set the presence on the client session
 *
 *  @param newPresence    The new presence to use
 *  @param successHandler A block called when the operation is successful
 *  @param errorHandler   A block called when an error occurs, passing a string describing the error
 */
- (void)setPresence:(NSObject*)newPresence successHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  Return the Endpoint ID of this client
 *
 *  @return The Endpoint ID of this client
 */
- (NSString*)getEndpointID;


/**
 *  Returns the group with the specified ID
 *
 *  @return The group with specified ID
 */
- (RespokeGroup*)getGroupWithID:(NSString*)groupID;


/**
 * Retrieve the history of messages that have been persisted for 1 or more groups. Only those
 * messages that have been marked to be persisted when sent will show up in the history. Only
 * the most recent message in each group will be retrieved - to pull more messages, use the
 * other method signature that allows `maxMessages` to be specified.
 *
 * @param groupIDs The groups to pull history for
 * @param successHandler The block called when this async operation has completed successfully
 * @param errorHandler The block called when this async operation has completed with an error
 */
- (void)getGroupHistoriesForGroupIDs:(NSArray*)groupIDs
                      successHandler:(void (^)(NSDictionary*))successHandler
                        errorHandler:(void (^)(NSString*))errorHandler;

/**
 * For the connected endpoint, fetch a record that describes every conversation 
 * that the server has history on. 
 *
 * @param successHandler The block called when this async operation has completed successfully.
 * @param errorHandler The block called when this async operation has completed with an error
 */
- (void)getConversations:(void (^)(NSDictionary *))successHandler
            errorHandler:(void (^)(NSString *))errorHandler;

/**
 * For each specified conversations, updates the "read" status up to the given
 *  timestamp. Messages older than the given timestamp will be considered "read" 
 *  for this endpoint.
 *
 * @param conversationStatuses An array of RespokeConversationReadStatus object 
 *      references.
 * @param successHandler The block called when this async operation has completed successfully.
 * @param errorHandler The block called when this async operation has completed with an error
 */
- (void)setConversationsRead:(NSArray *)conversationStatuses
              successHandler:(void (^)(NSDictionary *))successHandler
                errorHandler:(void (^)(NSString *))errorHandler;

/**
 * Retrieve the history of messages that have been persisted for 1 or more groups. Only those
 * messages that have been marked to be persisted when sent will show up in the history.
 *
 * @param groupIDs The groups to pull history for
 * @param maxMessages The maximum number of messages per group to pull. Must be >= 1
 * @param successHandler The block called when this async operation has completed successfully
 * @param errorHandler The block called when this async operation has completed with an error
 */
- (void)getGroupHistoriesForGroupIDs:(NSArray*)groupIDs maxMessages:(NSInteger)maxMessages
                      successHandler:(void (^)(NSDictionary*))successHandler
                        errorHandler:(void (^)(NSString*))errorHandler;


/**
 * Retrieve the history of messages that have been persisted for a specific group. Only those
 * messages that have been marked to be persisted when sent will show up in the history. Only
 * the 50 most recent messages in each group will be retrieved - to change the maximum number of
 * messages pulled, use the other method signature that allows `maxMessages` to be specified. To
 * retrieve messages further back in the history than right now, use the other method signature
 * that allows `before` to be specified.
 *
 * @param groupID The groups to pull history for
 * @param successHandler The block called when this async operation has completed successfully
 * @param errorHandler The block called when this async operation has completed with an error
 */
- (void)getGroupHistoryForGroupID:(NSString*)groupID
                   successHandler:(void (^)(NSArray*))successHandler
                     errorHandler:(void (^)(NSString*))errorHandler;


/**
 * Retrieve the history of messages that have been persisted for a specific group. Only those
 * messages that have been marked to be persisted when sent will show up in the history. To
 * retrieve messages further back in the history than right now, use the other method signature
 * that allows `before` to be specified.
 *
 * @param groupID The groups to pull history for
 * @param maxMessages The maximum number of messages per group to pull. Must be >= 1
 * @param successHandler The block called when this async operation has completed successfully
 * @param errorHandler The block called when this async operation has completed with an error
 */
- (void)getGroupHistoryForGroupID:(NSString*)groupID maxMessages:(NSInteger)maxMessages
                   successHandler:(void (^)(NSArray*))successHandler
                     errorHandler:(void (^)(NSString*))errorHandler;


/**
 * Retrieve the history of messages that have been persisted for a specific group. Only those
 * messages that have been marked to be persisted when sent will show up in the history.
 *
 * @param groupID The groups to pull history for
 * @param maxMessages The maximum number of messages per group to pull. Must be >= 1
 * @param before Limit messages to those with a timestamp before this value
 * @param successHandler The block called when this async operation has completed successfully
 * @param errorHandler The block called when this async operation has completed with an error
 */
- (void)getGroupHistoryForGroupID:(NSString*)groupID maxMessages:(NSInteger)maxMessages
                           before:(NSDate*)before successHandler:(void (^)(NSArray*))successHandler
                     errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  Convenience method for setting presence to "available".
 *
 *  @param successHandler A block called when the operation is successful
 *  @param errorHandler   A block called when an error occurs, passing a string describing the error
 */
- (void)setOnlineWithSuccessHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  Convenience method for setting presence to "unavailable".
 *
 *  @param successHandler A block called when the operation is successful
 *  @param errorHandler   A block called when an error occurs, passing a string describing the error
 */
- (void)setOfflineWithSuccessHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler;


@end


/**
 *  A delegate protocol to notify the receiver of events occurring with the client
 */
@protocol RespokeClientDelegate <NSObject>


/**
 *  Receive notification Respoke has successfully connected to the cloud.
 *
 *  @param sender The RespokeClient that has connected
 */
- (void)onConnect:(RespokeClient*)sender;


/**
 *  Receive notification Respoke has successfully disconnected from the cloud.
 *
 *  @param sender        The RespokeClient that has disconnected
 *  @param reconnecting  Indicates if the Respoke SDK is attempting to automatically reconnect
 */
- (void)onDisconnect:(RespokeClient*)sender reconnecting:(BOOL)reconnecting;


/**
 *  Handle an error that resulted from a method call.
 *
 *  @param error  The error that has occurred
 *  @param sender The RespokeClient that is reporting the error
 */
- (void)onError:(NSError *)error fromClient:(RespokeClient*)sender;


/**
 *  Receive notification that the client is receiving a call from a remote party.
 *
 *  @param call   A reference to the incoming RespokeCall object
 *  @param sender The RespokeClient that is receiving the call
 */
- (void)onCall:(RespokeCall*)call sender:(RespokeClient*)sender;


/**
 *  This event is fired when the logged-in endpoint is receiving a request to open a direct connection
 *  to another endpoint.  If the user wishes to allow the direct connection, calling 'accept' on the
 *  direct connection will allow the connection to be set up.
 */
- (void)onIncomingDirectConnection:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint;


@end


/**
 *  A delegate protocol to ask the receiver to resolve a list of presence values for an endpoint
 */
@protocol RespokeResolvePresenceDelegate <NSObject>


/**
 *  Resolve the presence among multiple connections belonging to a single endpoint
 *
 *  @param presenceArray An array of presence values
 *
 *  @return The resolved presence value to use
 */
- (NSObject*)resolvePresence:(NSArray*)presenceArray;


@end
