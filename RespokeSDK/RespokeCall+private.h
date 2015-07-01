//
//  RespokeCall+private.h
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

#import "RespokeCall.h"
#import "RespokeSignalingChannel.h"


@class RTCPeerConnection;


@interface RespokeCall (private)


/**
 *  Initialize a new Call with the specified signaling channel
 *
 *  @param channel   The signaling channel to use
 *  @param endpoint  The remote endpoint
 *  @param audioOnly If true, only audio is supported on this call
 *  @param directConnectionOnly  Indicates that this call is only for a direct connection
 *
 *  @return A newly initialized RespokeCall instance
 */
- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel endpoint:(RespokeEndpoint*)endpoint audioOnly:(BOOL)audioOnly directConnectionOnly:(BOOL)directConnectionOnly;

/**
 *  Initialize a new Call with the specified signaling channel
 *
 *  @param channel   The signaling channel to use
 *  @param endpointID  The remote endpointID
 *  @param type The remote endpointID type
 *  @param audioOnly If true, only audio is supported on this call
 *
 *  @return A newly initialized RespokeCall instance
 */
- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel endpointID:(NSString*)endpointID type:(NSString*)type audioOnly:(BOOL)newAudioOnly;

/**
 *  Initialize a new Call with the specified signaling channel and incoming SDP configuration
 *
 *  @param channel               The signaling channel to use
 *  @param sdp                   Incoming SDP configuration from a remote party attempting to call this client
 *  @param sessionID             The session ID of the incoming call
 *  @param connectionID          The remote connection ID initiating the call
 *  @param endpoint              The remote endpoint
 *  @param directConnectionOnly  Indicates that this call is only for a direct connection
 *
 *  @return A newly initialized RespokeCall instance
 */
- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel incomingCallSDP:(NSDictionary*)sdp sessionID:(NSString*)sessionID connectionID:(NSString*)connectionID endpointID:(NSString*)endpointID fromType:(NSString*)fromType endpoint:(RespokeEndpoint*)endpoint directConnectionOnly:(BOOL)directConnectionOnly timestamp:(NSDate*)timestamp;


/**
 *  Process ICE candidates suggested by the remote endpoint
 *
 *  @param candidates Array of candidates to evaluate
 */
- (void)iceCandidatesReceived:(NSArray*)candidates;


/**
 *  Start the outgoing call process
 */
- (void)startCall;


/**
 *  Process a hangup message from the received from the remote endpoint
 */
- (void)hangupReceived;


/**
 *  Process an answer message received from the remote endpoint
 *
 *  @param remoteSDP        Remote SDP data
 *  @param remoteConnection Remote connection that answered the call
 */
- (void)answerReceived:(NSDictionary*)remoteSDP fromConnection:(NSString*)remoteConnection;


/**
 *  Process a connected messsage received from the remote endpoint
 */
- (void)connectedReceived;


/**
 *  Get the session ID of this call
 *
 *  @return The session ID
 */
- (NSString*)getSessionID;


/**
 *  Return the current peer connection object
 */
- (RTCPeerConnection*)getPeerConnection;


/**
 *  Notify the call that the specified direct connection was accepted
 */
- (void)directConnectionDidAccept:(RespokeDirectConnection*)sender;


/**
 *  Notify the call that the specified direct connection opened
 */
- (void)directConnectionDidOpen:(RespokeDirectConnection*)sender;


/**
 *  Notify the call that the specified direct connection closed
 */
- (void)directConnectionDidClose:(RespokeDirectConnection*)sender;


/**
 *  Notify the call that the specified direct connection experienced an error
 */
- (void)directConnectionError:(RespokeDirectConnection*)sender;


@end
