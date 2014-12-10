//
//  RespokeDirectConnection.h+private.h
//  Respoke SDK
//
//  Created by Jason Adams on 10/23/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "RespokeDirectConnection.h"
#import "RespokeSignalingChannel.h"


@class RespokeCall;
@class RTCPeerConnection;
@class RTCDataChannel;


@interface RespokeDirectConnection (private)


/**
 *  Initialize a new direct connection instance
 *
 *  @param call The call implementing the direct connection
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithCall:(RespokeCall*)call;


/**
 *  Notify the direct connection instance that the peer connection has opened the specified data channel
 *
 *  @param dataChannel    The dataChannel that has opened
 */
- (void)peerConnectionDidOpenDataChannel:(RTCDataChannel *)dataChannel;


/**
 *  Establish a new direct connection instance with the peer connection for the call
 */
- (void)createDataChannel;


@end